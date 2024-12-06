# please change 'hostname' to your hostname
deploy:
	nix build .#darwinConfigurations.fanaka-stephan-mac.system \
	   --extra-experimental-features 'nix-command flakes'

	./result/sw/bin/darwin-rebuild switch --flake .#fanaka-stephan-mac
