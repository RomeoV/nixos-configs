{ pkgs, config, lib, ... }:
let
  repoDir = "/var/lib/blog/repo.git";
  wwwDir = "/var/lib/blog/www";
  workDir = "/var/lib/blog/checkout";

  postReceiveHook = pkgs.writeShellScript "post-receive" ''
    set -e
    export PATH="${lib.makeBinPath [ pkgs.git pkgs.zola pkgs.coreutils ]}:$PATH"
    echo "Deploying blog..."
    rm -rf ${workDir}
    git clone ${repoDir} ${workDir}
    cd ${workDir}
    git submodule update --init --recursive
    cd ${workDir}/zola
    zola build --base-url http://blog.mycloud --output-dir ${wwwDir}
    echo "Blog deployed successfully!"
  '';
in {
  systemd.tmpfiles.rules = [
    "d /var/lib/blog 0755 root root -"
    "d ${wwwDir} 0755 root root -"
  ];

  # Create bare repo and symlink the post-receive hook (updated on every deploy)
  system.activationScripts.blog-repo = lib.stringAfter [ "users" ] ''
    if [ ! -d "${repoDir}" ]; then
      ${pkgs.git}/bin/git init --bare "${repoDir}"
    fi
    ln -sf ${postReceiveHook} "${repoDir}/hooks/post-receive"
  '';
}
