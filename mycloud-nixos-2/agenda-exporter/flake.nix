{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Your custom ox-html.el file
        myOxHtml = ./ox-html.el;


        # Custom Emacs with our modified packages
        myEmacs = pkgs.emacs.pkgs.withPackages (epkgs: [
          epkgs.org
          epkgs.htmlize
          # Any other packages needed for batch export
        ]);

        # Script to generate HTML from todo.org
        exportScript = pkgs.writeShellScriptBin "export-todos" ''
          # Create a temporary directory for the custom files
          TEMP_DIR=$(mktemp -d)
          cp ${myOxHtml} $TEMP_DIR/ox-html.el

          # Create web directories
          mkdir -p /var/www/todos/todos
          mkdir -p /var/www/todos/agenda

          # Run Emacs with the custom file loaded first
          ${myEmacs}/bin/emacs --batch \
            --directory $TEMP_DIR \
            --eval "(require 'ox-html)" \
            --visit "/home/syncthing/todo_notes/todo.org" \
            --eval "(setq org-html-postamble nil \
                          org-export-with-planning t \
                          org-export-with-planning t \
                          org-export-with-broken-links t \
                          org-export-with-archived-trees nil )" \
            --eval "(setq org-export-select-tags '(\"shared\"))" \
            --funcall org-html-export-to-html \
            --kill

          # Move todo HTML to the right location
          cp /home/syncthing/todo_notes/todo.html /var/www/todos/todos/index.html

          # Set appropriate permissions
          # chown -R nginx:nginx /var/www/todos
          # chmod -R 765 /var/www/todos

          # Clean up
          rm -rf $TEMP_DIR
        '';
      in {
        # Development shell for manual testing
        devShells.default = pkgs.mkShell {
          buildInputs = [ myEmacs exportScript ];
        };

        # Packages that can be used in NixOS configurations
        packages = {
          inherit myEmacs exportScript;
          default = exportScript;
        };

        # Apps that can be run with `nix run`
        apps.default = {
          type = "app";
          program = "${exportScript}/bin/export-todos";
        };
      }
    );
}
