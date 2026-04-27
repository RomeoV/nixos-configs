{ ... }: {
  age.secrets = {
    nextcloud_admin_pass = {
      file = ../../secrets/nextcloud_admin_pass.age;
      owner = "nextcloud";
    };
    hetzner_private_key = {
      file = ../../secrets/hetzner_private_key.age;
      owner = "root";
    };
    agenda-password.file = ../../secrets/agenda-password.age;
    backblaze_env_2.file = ../../secrets/backblaze_env_2.age;
    backblaze_repo_2.file = ../../secrets/backblaze_repo_2.age;
    backblaze_password_2.file = ../../secrets/backblaze_password_2.age;
    mlflow-artifacts-key.file = ../../secrets/mlflow-artifacts-key.age;
    paperless-admin-password.file = ../../secrets/paperless-admin-password.age;
    syncthing-key.file = ../../secrets/syncthing-key.age;
    syncthing-cert.file = ../../secrets/syncthing-cert.age;
    porkbun-secret-api-key-both.file = ../../secrets/porkbun-secret-api-key-both.age;
    github-key.file = ../../secrets/github-key.age;
    rclone-config-immich-object-storage.file = ../../secrets/rclone-config-immich-object-storage.age;
    nextcloud-object-storage-secret.file = ../../secrets/nextcloud-object-storage-secret.age;
    # openclaw API key managed imperatively via auth-profiles.json
    openclaw-telegram-token = {
      file = ../../secrets/openclaw-telegram-token.age;
      owner = "openclaw";
    };
    storage-box-cifs-credentials = {
      file = ../../secrets/storage-box-cifs-credentials.age;
      owner = "root";
    };
    stanford-oauth-tokens = {
      file = ../../secrets/stanford-oauth-tokens.age;
      owner = "mailsync";
      group = "mailsync";
      mode = "0400";
    };
  };
}
