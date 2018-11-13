docker run \
	--name neo4j \
	--rm \
	--publish=7473:7473 \
	--publish=7474:7474 \
	--publish=7687:7687 \
	-v /${HOME}/neo4j/data:/data \
	-v /${HOME}/neo4j/logs:/logs \
	-v /${HOME}/neo4j/import:/import \
	-v /${HOME}/neo4j/plugins:/plugins \
	-p 80:7474 \
	-p 8080:7687 \
	-e NEO4J_dbms_security_procedures_unrestricted=apoc.\\\* \
	-e NEO4J_apoc_export_file_enabled=true \
	-e NEO4J_apoc_import_file_enabled=true \
	-e NEO4J_apoc_import_file_use__neo4j__config=true \
	neo4j:3.4.9
