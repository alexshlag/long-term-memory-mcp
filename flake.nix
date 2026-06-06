{
  description = "Глобальная нативная установка Long-Term Memory MCP для NixOS 26.05";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Окружение Python со всеми необходимыми MCP-серверу зависимостями из Nixpkgs
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          chromadb
          sentence-transformers
          fastmcp
          huggingface-hub
        ]);
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "long-term-memory-mcp";
          version = "1.0.0";

          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            mkdir -p $out/share/long-term-memory-mcp
            mkdir -p $out/bin

            # Копируем исходные файлы скриптов
            cp long_term_memory_mcp.py $out/share/long-term-memory-mcp/
            cp memory_manager_gui.py $out/share/long-term-memory-mcp/

            # Создаем исполняемый бинарник-обертку в системный PATH
            makeWrapper ${pythonEnv}/bin/python $out/bin/long-term-memory-mcp \
              --add-flags "$out/share/long-term-memory-mcp/long_term_memory_mcp.py"
          '';

          meta = with pkgs.lib; {
            description = "Robust Long‑Term Memory MCP for Language Models";
            homepage = "https://github.com/alexshlag/long-term-memory-mcp";
            license = licenses.mit;
            platforms = platforms.linux;
          };
        };
      }) // {

      # Модуль NixOS для декларативной интеграции в configuration.nix
      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.services.long-term-memory-mcp;
          serverPkg = self.packages.${pkgs.system}.default;
        in {
          options.services.long-term-memory-mcp = {
            enable = lib.mkEnableOption "Включение глобального Long-Term Memory MCP сервера";
            dataDir = lib.mkOption {
              type = lib.types.str;
              default = "/var/lib/long-term-memory-mcp";
              description = "Директория для хранения базы знаний SQLite, ChromaDB и бэкапов";
            };
          };

          config = lib.mkIf cfg.enable {
            # Добавляем утилиту глобально в систему (появится команда long-term-memory-mcp)
            environment.systemPackages = [ serverPkg ];

            # Автоматически создаем systemd-службу, если сервер должен работать в фоне
            systemd.services.long-term-memory-mcp = {
              description = "Long-Term Memory MCP Server Daemon";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];
              
              environment = {
                AI_COMPANION_DATA_DIR = cfg.dataDir;
              };

              serviceConfig = {
                ExecStart = "${serverPkg}/bin/long-term-memory-mcp";
                Restart = "always";
                User = "mcp-memory";
                Group = "mcp-memory";
                StateDirectory = "long-term-memory-mcp";
                WorkingDirectory = cfg.dataDir;
                PrivateTmp = true;
                ProtectSystem = "full";
              };
            };

            # Создаем системного пользователя для изоляции работы БД
            users.users.mcp-memory = {
              isSystemUser = true;
              group = "mcp-memory";
              home = cfg.dataDir;
              createHome = true;
            };
            users.groups.mcp-memory = {};
          };
        };
    };
}
