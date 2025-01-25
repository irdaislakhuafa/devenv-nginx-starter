{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  nginx = {
    enable = true;
    user = "nginx";
    certs = {
      dir = "${config.env.DEVENV_ROOT}/certs";
      key = "server.key";
      cert = "server.crt";
    };
    domain = {
      dev = "127.0.0.1";
    };
    apps = [
      rec {
        from = "/backend";
        protocol = "http";
        host = "127.0.0.1";
        port = "8080";
        uri = "";
        full_uri = "${protocol}://${host}:${port}${uri}";
      }
    ];
  };
in
{
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [
    pkgs.openssl
  ];

  enterShell =
    let
      pm = "process-compose";
    in
    ''
      alias pm=${pm};
      gen-ssl;
    '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
  '';

  # See full reference at https://devenv.sh/reference/options/

  # proccess config
  process = {
    managers = {
      process-compose = {
        tui = {
          enable = false;
        };
      };
    };
  };

  # nginx and ssl certificate
  scripts.gen-ssl.exec = ''
    mkdir -pv ${nginx.certs.dir};
    openssl req \
      -x509 \
      -nodes \
      -days 365 \
      -newkey rsa:2048 \
      -keyout ${nginx.certs.dir}/${nginx.certs.key} \
      -out ${nginx.certs.dir}/${nginx.certs.cert} \
      -subj "/CN=${nginx.domain.dev}"
  '';
  scripts."pm-list".exec = ''
    process-compose list --output wide;
  '';
  scripts."pm-up".exec = ''
    process-compose up -D; 
  '';

  containers.nginx = {
    name = "nginx";
    # copyToRoot = null;
    startupCommand = "pm-up";
  };
  services.nginx = {
    enable = nginx.enable;
    package = pkgs.nginx;
    httpConfig = ''
      # user ${nginx.user};

      keepalive_timeout 65;

      server {
        listen 443 ssl;
        listen [::]:443 ssl;
        server_name ${nginx.domain.dev};

        ssl_certificate ${nginx.certs.dir}/${nginx.certs.cert};
        ssl_certificate_key ${nginx.certs.dir}/${nginx.certs.key};

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;
        
        ${lib.foldl' (
          merged: current:
          merged
          + ''
            location ${current.from} {
              rewrite ^${current.from}(/.*)$ $1 break;
              proxy_pass ${current.full_uri};
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            }         
          ''
        ) "" nginx.apps}
      }
    '';
  };
}
