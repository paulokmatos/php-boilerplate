test:
	./vendor/bin/phpunit tests/ --verbose

stan: 
	./vendor/bin/phpstan analyse -l 6 src tests

validate-stan:
	./vendor/bin/phpstan analyse -l 6 src tests

validate-phpcs:
	./vendor/bin/php-cs-fixer fix src -v --dry-run
	./vendor/bin/php-cs-fixer fix tests -v --dry-run

cs-fix:
	./vendor/bin/php-cs-fixer fix tests -v
	./vendor/bin/php-cs-fixer fix src -v