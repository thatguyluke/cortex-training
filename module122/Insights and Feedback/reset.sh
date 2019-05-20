#!/bin/bash

# Load all the data ... into Managed Content
cortex content upload newsAgent/datasets/newsArticles.json data/datasets/newsArticles.json
cortex content upload newsAgent/profiles/tom.json data/profiles/tom.json
cortex content upload newsAgent/profiles/jim.json data/profiles/jim.json
