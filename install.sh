# Run as root - eventually use sudo
# In the case, you hav enot installed sudo, go it (login as root and type "apt-get install sudo" and "sudo adduser <username> sudo")
# Then it is necessary to log as user not as root. Elasticsearch can not run root because of security reasons.

# Update upgrade
sudo apt-get update
sudo apt-get upgrade -y


# Install Java 8
sudo apt-get install software-properties-common -y
sudo add-apt-repository "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main"
sudo apt-get update
sudo apt-get install oracle-java8-installer -y
# Accept licence


# Install Elasticsearch
curl -L -O -s https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.1.2.tar.gz
tar -xvf elasticsearch-5.1.2.tar.gz
cd elasticsearch-5.1.2
mkdir config/hunspell
mkdir config/hunspell/cs_CZ
cd config/hunspell/cs_CZ
curl -sL -o cs_CZ.aff https://github.com/pavoltravnik/elasticsearch-cz/raw/master/cs_CZ.aff
curl -sL -o cs_CZ.dic https://github.com/pavoltravnik/elasticsearch-cz/raw/master/cs_CZ.dic
cd ../../../bin
sudo ./elasticsearch-plugin install analysis-icu
nohup ./elasticsearch &

echo $! > run.pid




# Create new Index
curl -XPUT 'localhost:9200/my_index?pretty&pretty' -d '{
  "settings": {
    "analysis": {
      "filter": {
        "czech_stop": {
          "type":       "stop",
          "stopwords":  "_czech_" 
        },
        "czech_stemmer": {
          "type":       "stemmer",
          "language":   "czech"
        },
        "cs_CZ" : {
                "type" : "hunspell",
                "locale" : "cs_CZ",
                "dedup" : true
        }
      },
      "analyzer": {
        "czech": {
          "tokenizer":  "standard",
          "filter": [
            "icu_folding",
            "lowercase",
            "czech_stop",
            "czech_stemmer",
            "cs_CZ"
          ]
        }
      }
    }
  }
}'


# Set mapping of index
curl -XPUT 'localhost:9200/my_index/_mapping/user?pretty&pretty' -d '
{
  "properties": {
    "name": {
      "type": "string",
      "fields": {
        "sort": {
          "type": "string",
          "analyzer": "czech"
        }
      }
    }
  }
}'


# Create new item
curl -XPUT 'localhost:9200/my_index/user/1?pretty&pretty' -d'
{
  "name": "John Škoda"
}'

$ Search the item
curl -XGET 'localhost:9200/my_index/_search?pretty' -d'
{
  "query": { "match": { "name.sort": "Skod" } }
}'

