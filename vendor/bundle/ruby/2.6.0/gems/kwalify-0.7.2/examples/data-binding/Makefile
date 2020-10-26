all:	main.rb models.rb
	ruby main.rb

models.rb:	BABEL.schema.yaml
	kwalify -a genclass-ruby -f BABEL.schema.yaml -tP --hashlike --module=Babel --initialize=false > models.rb

clean:
	rm -f models.rb
