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


def main(params):
    try:
        cortex_params = InputMessage.from_params(params)

        # Download profile attributes (if it exists ...)
        profileAttributes = safe_load_list_of_jsons_from_managed_content(cortex_params, "newsAgent/profiles/{}.json".format(cortex_params.payload.get("profileId")))
        # eprint(profileAttributes)

        # Download news articles to present ...
        artilces = safe_load_list_of_jsons_from_managed_content(cortex_params, "newsAgent/datasets/newsArticles.json")
        # eprint(artilces)

        # if the user does not have a profile, return 10 random artilces ...
        if not profileAttributes:
            scored_articles = [(0, x) for x in random.sample(artilces, 10)]
            eprint("No Profile for User...")
        # Here on out, we are assuming the user has a profile ...
        else:
            # Get User Affinity Score Per Keyword
            user_keyword_affinities = determine_user_keyword_affinity_score(profileAttributes)
            # eprint(user_keyword_affinities)
            # Score Each Article Against Users Afinnity Scores & Sort Them...
            scored_articles = list(sorted(
                [score_article(a, user_keyword_affinities) for a in artilces],
                key=lambda x: -1 * x[0]
            ))

        eprint(scored_articles)
        # Take the top 3 Articles ...
        insights = turn_scored_articles_into_insights(
            cortex_params.payload.get("profileId"),
            scored_articles[:3]
        )
        
        # - [ ] TODO: Download Insights File and Append Newly Generated Insights to it
        eprint(insights)
        return OutputMessage.create().with_payload({
            "profileId": cortex_params.payload.get("profileId"),
            "insights": insights
        }).to_params()
    except Exception as e:
        return OutputMessage.create().with_payload({'message': str(e)}).to_params()
