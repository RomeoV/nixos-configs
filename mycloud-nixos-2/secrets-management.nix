{ ... }:

{
  age.secrets = {
    nextcloud_admin_pass = {
      file = agenix/nextcloud_admin_pass.age;
      owner = "nextcloud";
    };
    hetzner_private_key = {
      file = agenix/hetzner_private_key.age;
      owner = "root";
    };
    backblaze_env.file = agenix/backblaze_env.age;
    backblaze_repo.file = agenix/backblaze_repo.age;
    backblaze_password.file = agenix/backblaze_password.age;
  };
}
