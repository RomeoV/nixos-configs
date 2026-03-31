{ ... }: {
  age.secrets = {
    nextcloud_admin_pass = {
      file = agenix/nextcloud_admin_pass.age;
      owner = "nextcloud";
    };
    hetzner_private_key = {
      file = agenix/hetzner_private_key.age;
      owner = "root";
    };
    agenda-password.file = agenix/agenda-password.age;
    backblaze_env_2.file = agenix/backblaze_env_2.age;
    backblaze_repo_2.file = agenix/backblaze_repo_2.age;
    backblaze_password_2.file = agenix/backblaze_password_2.age;
    mlflow-artifacts-key.file = agenix/mlflow-artifacts-key.age;
    paperless-admin-password.file = agenix/paperless-admin-password.age;
    syncthing-key.file = agenix/syncthing-key.age;
    syncthing-cert.file = agenix/syncthing-cert.age;
    porkbun-secret-api-key-both.file = agenix/porkbun-secret-api-key-both.age;
    github-key.file = agenix/github-key.age;
    rclone-config-immich-object-storage.file = agenix/rclone-config-immich-object-storage.age;
    nextcloud-object-storage-secret.file = agenix/nextcloud-object-storage-secret.age;
    # zeroclaw secrets removed - using openclaw now
    openclaw-api-key = {
      file = agenix/openclaw-anthropic-key.age;  # Same file as zeroclaw used
      owner = "openclaw";
    };
    openclaw-telegram-token = {
      file = agenix/openclaw-telegram-token.age;  # Same file as zeroclaw used
      owner = "openclaw";
    };
    storage-box-cifs-credentials = {
      file = agenix/storage-box-cifs-credentials.age;
      owner = "root";
    };
    stanford-oauth-tokens = {
      file = agenix/stanford-oauth-tokens.age;
      owner = "mailsync";
      group = "mailsync";
      mode = "0400";
    };
  };
}
