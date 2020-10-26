
all:
	kwalify -lm tapkit.schema.yaml
	kwalify -lf tapkit.schema.yaml tapkit.yaml
	kwalify -a genclass-ruby -lf tapkit.schema.yaml --module=Tapkit > tapkit.rb
#	kwalify -a genclass-java -lf tapkit.schema.yaml --package=tapkit


clean:
	rm -f tapkit.rb
