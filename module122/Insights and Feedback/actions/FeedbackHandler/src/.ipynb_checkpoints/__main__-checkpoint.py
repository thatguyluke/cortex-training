import cortex_client
from cortex_client import InputMessage, OutputMessage
from cortex_client.client import _Client, build_client
from cortex_client.connectionclient import ConnectionClient

import json
import random
import ssl
import sys
import traceback
import uuid
import urllib.parse
import base64
import arrow
import itertools
from collections import Counter


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def safe_load_list_of_jsons_from_managed_content(cortex_params, key):
    cc = build_client(ConnectionClient, cortex_params, "2")
    try:
        content = str(cc.download(key).read(), 'utf-8')
    except Exception:
        eprint(traceback.format_exc())
        content = ""
    return [json.loads(line) for line in content.split("\n") if line.strip()]


def safe_save_list_of_jsons_to_managed_content(cortex_params, key, list_of_jsons):
    cc = build_client(ConnectionClient, cortex_params, "2")
    try:
        response = cc.upload(
            key,
            "file.json",
            "\n".join([json.dumps(x) for x in list_of_jsons if x]),
            "application/json-lines"
        )
        eprint(response)
    except Exception:
        eprint(traceback.format_exc())


def determine_user_keyword_affinity_score(profile_attributes):
    return dict(
        map(
            lambda x: (x["value"]["keyword"], x["value"]["total"]),
            filter(lambda x: x["attributeId"] == "totalTimesUserLikedInsightWithKeyword", profile_attributes)
        )
    )


def score_article(article, user_keyword_affinities):
    return (
        sum([user_keyword_affinities.get(k, 0) for k in article["keywords"]]),
        article
    )


def turn_scored_articles_into_insights(profileId, scored_articles):
    return [{
        "insightId": str(uuid.uuid4()),
        "profileId": profileId,
        "dateGenerated": str(arrow.utcnow()),
        "score": a[0],
        "content": a[1]
    } for a in scored_articles]


def recreate_keyword_based_profile_attributes(profileId, total_like_counts):
    return [
        {"profileId": profileId, "attributeId": "totalTimesUserLikedInsightWithKeyword", "value": {"keyword": k, "total": v}}
        for k, v in dict(total_like_counts).items()
    ]


def main(params):
    try:
        cortex_params = InputMessage.from_params(params)
        profile_key = "newsAgent/profiles/{}.json".format(cortex_params.payload.get("profileId"))

        # Download users current profile attributes (if it exists ...)
        profileAttributes = safe_load_list_of_jsons_from_managed_content(cortex_params, profile_key)
        eprint(profileAttributes)

        userKeywordLikes = Counter(determine_user_keyword_affinity_score(profileAttributes))
        eprint(userKeywordLikes)

        keywordsOfInsightsLiked = Counter(list(itertools.chain.from_iterable(
            [set(x["content"]["keywords"]) for x in cortex_params.payload.get("insightsLiked", [])]
        )))
        eprint(keywordsOfInsightsLiked)

        updatedKeywordLikeCounts = userKeywordLikes + keywordsOfInsightsLiked
        new_profile_attributes = recreate_keyword_based_profile_attributes(
            cortex_params.payload.get("profileId"),
            updatedKeywordLikeCounts
        )
        eprint(new_profile_attributes)

        safe_save_list_of_jsons_to_managed_content(cortex_params, profile_key, new_profile_attributes)

        return OutputMessage.create().with_payload({
            "profileId": cortex_params.payload.get("profileId")
        }).to_params()
    except Exception as e:
        return OutputMessage.create().with_payload({'message': str(e)}).to_params()
