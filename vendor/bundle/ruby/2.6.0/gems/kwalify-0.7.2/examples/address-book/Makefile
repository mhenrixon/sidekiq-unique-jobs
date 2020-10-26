
all:
	kwalify -lm address-book.schema.yaml
	kwalify -lf address-book.schema.yaml address-book.yaml
	kwalify -a genclass-ruby -lf address-book.schema.yaml > address-book.rb
#	kwalify -a genclass-java -lf address-book.schema.yaml


clean:
	rm -f address-book.rb
