{
  description = "Default Flake";

  inputs = {
    # keep-sorted start block=yes
    fenix = {
      url = "https://flakehub.com/f/nix-community/fenix/0.1.*";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    flake-checker = {
      url = "github:DeterminateSystems/flake-checker";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        fenix = {
          follows = "fenix";
        };
        naersk = {
          follows = "naersk";
        };
      };
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs = {
        nixpkgs-lib = {
          follows = "nixpkgs";
        };
      };
    };
    naersk = {
      url = "https://flakehub.com/f/nix-community/naersk/0.1.*";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    nixpkgs = {
      url = "https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-compat = {
          follows = "flake-compat";
        };
      };
    };
    systems = {
      url = "github:nix-systems/default";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    # keep-sorted end
  };

  outputs =
    {
      flake-parts,
      systems,
      flake-checker,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        inputs,
        ...
      }:
      {
        systems = import systems;
        imports = [
          inputs.pre-commit-hooks.flakeModule
          inputs.treefmt-nix.flakeModule
        ];

        perSystem =
          {
            system,
            pkgs,
            config,
            inputs',
            ...
          }:
          let
            treefmtBuild = config.treefmt.build;
          in
          {
            _module = {
              args = {
                pkgs = import inputs.nixpkgs {
                  inherit system;
                  config = {
                    allowUnfree = true;
                  };
                };
              };
            };
            checks = config.packages;
            devShells = {
              default = pkgs.mkShell {
                PFPATH = "${
                  pkgs.buildEnv {
                    name = "zsh-comp";
                    paths = config.devShells.default.nativeBuildInputs;
                    pathsToLink = [ "/share/zsh" ];
                  }
                }/share/zsh/site-functions";
                packages = with pkgs; [
                  nil
                  efm-langserver
                ];
                inputsFrom = [
                  config.pre-commit.devShell
                  treefmtBuild.devShell
                ];
              };
            };
            pre-commit = {
              check = {
                enable = true;
              };
              settings = {
                src = ./.;
                hooks = {
                  # keep-sorted start block=yes
                  flake-checker = {
                    enable = true;
                    package = inputs'.flake-checker.packages.flake-checker;
                  };
                  treefmt = {
                    enable = true;
                    packageOverrides = {
                      treefmt = treefmtBuild.wrapper;
                    };
                  };
                  # keep-sorted end
                };
              };
            };
            formatter = treefmtBuild.wrapper;
            treefmt = {
              projectRootFile = "flake.nix";
              flakeCheck = false;
              programs = {
                # keep-sorted start block=yes
                deadnix = {
                  enable = true;
                };
                keep-sorted = {
                  enable = true;
                };
                nixfmt = {
                  enable = true;
                };
                statix = {
                  enable = true;
                };
                # keep-sorted end
              };
            };
          };
      }
    );
}
