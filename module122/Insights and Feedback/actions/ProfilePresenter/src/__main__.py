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


def joint_score_of_affinities(affinity_dict, affinities):
    return sum([y for x, y in affinity_dict.items() if x in affinities])


def main(params):
    try:
        cortex_params = InputMessage.from_params(params)
        profile_key = "newsAgent/profiles/{}.json".format(cortex_params.payload.get("profileId"))

        # Download users current profile attributes (if it exists ...)
        profileAttributes = safe_load_list_of_jsons_from_managed_content(cortex_params, profile_key)
        eprint(profileAttributes)

        user_keyword_affinities = determine_user_keyword_affinity_score(profileAttributes)

        # List the users keywords sorted
        userKeywordLikes = [
            {"keyword": y[0], "score": y[1]}
            for y in sorted(
                user_keyword_affinities.items(),
                key=lambda x: -1 * x[1]
            )
        ]
        eprint(userKeywordLikes)

        # List the users topics sorted
        topics = {
            topic["topic"]: topic["keywords"]
            for topic in safe_load_list_of_jsons_from_managed_content(cortex_params, "newsAgent/datasets/topics.json")
        }
        eprint(topics)

        # Determine User Topic Affinities ...
        userTopicLikes = [
            {"topic": topic, "score": joint_score_of_affinities(user_keyword_affinities, keywords)}
            for topic, keywords in topics.items()
        ]
        eprint(userTopicLikes)

        return OutputMessage.create().with_payload({
            "profileId": cortex_params.payload.get("profileId"),
            "profileAttributes": {
                "userAffinityTowardsInsightsWithKeywords": userKeywordLikes,
                "userAffinityTowardsInsightsAboutTopics": userTopicLikes,
            }
        }).to_params()
    except Exception as e:
        return OutputMessage.create().with_payload({'message': str(e)}).to_params()
