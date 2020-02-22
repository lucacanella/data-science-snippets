# prepare environment (if you need to install docker follow: https://docs.docker.com/install/linux/docker-ce/debian/)
cd ~
USER_N4J_HOME=~/dockerpersistence/neo4j
mkdir -p $USER_N4J_HOME
mkdir $USER_N4J_HOME/plugins/
mkdir $USER_N4J_HOME/logs/
mkdir $USER_N4J_HOME/data/
mkdir $USER_N4J_HOME/import/
mkdir $USER_N4J_HOME/conf/

chown systemd-network:systemd-journal $USER_N4J_HOME -R

#install apoc procedures
cd $USER_N4J_HOME/plugins/
wget https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/4.0.0.3/apoc-4.0.0.3-all.jar

#run neo4j 4.0.0 docker container
docker run \
	--name neo4j \
	--rm \
	--publish=7473:7473 \
	--publish=7474:7474 \
	--publish=7687:7687 \
	--publish=80:7474 \
	--publish=8080:7687 \
	-v $USER_N4J_HOME/data:/data \
	-v $USER_N4J_HOME/logs:/logs \
	-v $USER_N4J_HOME/import:/import \
	-v $USER_N4J_HOME/plugins:/plugins \
  -v $USER_N4J_HOME/conf:/var/lib/neo4j/conf \
	-e NEO4J_dbms_security_procedures_unrestricted=apoc.\\\* \
	-e NEO4J_apoc_export_file_enabled=true \
	-e NEO4J_apoc_import_file_enabled=true \
	-e NEO4J_apoc_import_file_use__neo4j__config=true \
  -e dbms.allow_upgrade=true \
	--env=NEO4J_dbms_memory_heap_initial__size=512m --env=NEO4J_dbms_memory_heap_max__size=2G \
	neo4j:4.0.0

#download the dataset
cd $USER_N4J_HOME/import
wget http://files.grouplens.org/datasets/movielens/ml-1m.zip
unzip ml-1m.zip

#make some changes on the file before importing
cd $USER_N4J_HOME/import/ml-1m/

sed -e 's/$/::RATED/' -i ratings.dat
sed -e 's/$/::Movie/' -i movies.dat
sed -e 's/$/::User/' -i users.dat
sed -i 's/::/§/g' *.dat

echo ':ID(Movie)§name§genres§:LABEL' > /tmp/movies.dat
cat movies.dat >> /tmp/movies.dat
cp /tmp/movies.dat movies.dat

echo ':ID(User)§gender§age:int§occupation_code§zipcode:string§:LABEL' >> /tmp/users.dat
cat users.dat >> /tmp/users.dat
cp /tmp/users.dat users.dat

echo ':START_ID(User)§:END_ID(Movie)§rating:double§time:int§:TYPE' >> /tmp/ratings.dat
cat ratings.dat >> /tmp/ratings.dat
cp /tmp/ratings.dat ratings.dat

rm /tmp/movies.dat /tmp/ratings.dat /tmp/users.dat

#jump in the docker container and import
docker exec -ti neo4j bash
cd $NEO4J_HOME/data/databases
#remove default database
rm $NEO4J_HOME/data/databases/neo4j rm $NEO4J_HOME/data/transactions/neo4j/ -rf

#Option 1: lean import command and the change permissions if needed
/var/lib/neo4j/bin/neo4j-admin import \
	--nodes=User="/import/ml-1m/users.dat" \
	--nodes=Movie="/import/ml-1m/movies.dat" \
	--relationships=RATED="/import/ml-1m/ratings.dat" \
	--delimiter="§" \
	--array-delimiter="|" \
  --skip-bad-relationships=true \
	--database neo4j
#change file permissions
chown neo4j:neo4j /data/databases/neo4j

#Option 2: even better... use neo4j user with sudo (if needed install sudo: apt-get update && apt-get install sudo)
sudo -u neo4j JAVA_HOME=$JAVA_HOME /var/lib/neo4j/bin/neo4j-admin import --relationships=/import/ml-1m/ratings.dat --nodes="User"=/import/ml-1m/users.dat --nodes="Movie"=/import/ml-1m/movies.dat --delimiter="§" --array-delimiter="|" --database neo4j

# 
# Restart the container if you still can't see the database in neo4j browser
# 