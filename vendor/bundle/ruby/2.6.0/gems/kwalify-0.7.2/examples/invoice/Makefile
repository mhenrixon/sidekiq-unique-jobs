all:
	kwalify -lm invoice.schema.yaml
	kwalify -lf invoice.schema.yaml invoice.yaml
	kwalify -a genclass-ruby -lf invoice.schema.yaml > invoice.rb
#	kwalify -a genclass-java -lf invoice.schema.yaml


clean:
	rm -f invoice.rb
