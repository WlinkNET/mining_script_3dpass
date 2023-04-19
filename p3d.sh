#!/bin/bash

R='\033[0;31m'
G='\033[0;32m'
NC='\033[0m' # No Color
Y='\033[0;33m'
echo -e "${Y}This script is used to run all the parameters for mining P3D coin. Below you have all the explanations and
instructions that you can use either for the solo or pool version. If you choose the solo version, you can generate a
new address or update an existing one, in which case you must have the memo seed and public key at hand. For the pool
version, you must have the memo seed and address prepared. I hope this script makes your setup easier and that you will
be satisfied. You can also donate for further development.${NC}"
echo -e "${R}Do you want to continue? (Y/N)${NC}"
read -r choice
#read -p "${R}Do you want to continue? (Y/N)${NC}" choice
case "$choice" in
y|Y ) echo -e "${G}You chose to continue.${NC}";;
n|N ) echo -e "${R}You chose to exit. Goodbye!${NC}"; exit 0;;

* ) echo "${R}Invalid option. Please try again.${NC}"; exit 1;;
esac
# Check if the necessary dependencies are available
#!/bin/bash

dependencies=("curl" "git" "wget" "clang" "cmake" "gcc" "screen")
missing_deps=()

if [[ $(uname) == "Darwin" ]]; then
    dependencies+=("libomp")
fi

if [[ $(uname) == "Linux" ]]; then
    dependencies+=("libclang-dev" "libssl-dev")
fi

for dep in "${dependencies[@]}"
do
    if ! command -v $dep &> /dev/null
    then
        missing_deps+=("$dep")
    fi
done

if [ ${#missing_deps[@]} -gt 0 ]; then
    echo -e "The following dependencies are missing: ${missing_deps[*]}"
    echo -e "I am installing the missing dependencies."
    
    if [[ $(uname) == "Darwin" ]]; then
        if ! command -v brew &> /dev/null; then
            echo -e "Homebrew is not installed. I am installing Homebrew now."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install ${missing_deps[@]}
    fi
    
    if [[ $(uname) == "Linux" ]]; then
        apt-get update
        apt-get install -y ${missing_deps[@]}
    fi
fi

# Check if Node.js is installed and get its version
node_version=$(node -v 2>/dev/null)

# Compare Node.js version with the required version (14 in this example)
if [ -z "$node_version" ] || [ "$(printf '%s\n' "${node_version#v}" "16.0.0" | sort -V | head -n1)" = "${node_version#v}" ]; then
  echo "Node.js is not installed or version is less than 16.0.0. Installing..."
  # Install Node.js using package manager (apt-get for Ubuntu/Debian)
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
  echo -e "${G}Node.js installed successfully.${NC}"
else
  echo -e "${G}Node.js version $node_version is greater than or equal to 16.0.0. No action required.${NC}"
fi
rust_version=$(rustc --version 2>/dev/null)

# Compare Rust version with the required version (1.7 in this example)
if [ -z "$rust_version" ] || [[ "$rust_version" =~ ([0-9]+\.[0-9]+\.[0-9]+) && ${BASH_REMATCH[1]} < "1.70.0" ]]; then
  echo "Rust is not installed or version is less "${rust_version#rustc }" than 1.70.0. Installing nightly toolchain and wasm32-unknown-unknown target..."
  # Install Rust nightly toolchain and wasm32-unknown-unknown target
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain nightly
  source $HOME/.cargo/env
  rustup target add wasm32-unknown-unknown
  echo -e "${G}Rust installed successfully with nightly toolchain and wasm32-unknown-unknown target.${NC}"
else
  echo -e "${G}Rust version $rust_version is greater than or equal to 1.70.0. No action required.${NC}"
fi

if rustup toolchain list | grep nightly &> /dev/null &&
    rustup target list | grep wasm32-unknown &> /dev/null
then
    echo -e "${Y}Rust nightly toolchain i wasm32-unknown target already installed.${NC}"
else
    echo -e "${Y}Installing Rust nightly toolchain i wasm32-unknown target.${NC}"
    rustup install nightly
    rustup target add wasm32-unknown-unknown --toolchain nightly
    echo -e "${G}Rust dependency nightly and wasm32 succesfully installed.${NC}"
fi

# Prompt for node type
    echo -e "${R}If you use pool option please prepare address and memo seed${NC}"
    echo "Please choose the type of node you want to run:"
    echo "1. Solo node"
    echo "2. Pool node"
    read -p "Enter your choice (1 or 2): " node_choice

    case $node_choice in
        1)
            # Git clone 3DP repository
        if [ -d "3DP" ]; then
            echo -e "${Y}3DP repo already exist.${NC}"
        else
            git clone https://github.com/3Dpass/3DP.git
        fi
        # Enter 3DP folder and execute cargo build release
        cd 3DP
        source $HOME/.cargo/env
        rustup update nightly
        rustup target add wasm32-unknown-unknown --toolchain nightly
        git pull
        cargo build --release

        # Run poscan-consensus if the installation is successful
        if [ -f "target/release/poscan-consensus" ]; then
            BASE_PATH="$HOME/3dp-chain/"
            echo -e "${G}Successfully installed. Running poscan-consensus...${NC}"
            sleep 2

            # Prompt for memo_seed
            read -p "Do you want to generate a new address (g) or enter an existing one (u)? " choice
            if [[ $choice =~ ^[Gg]$ ]]; then
                echo -e "${G}Generating a new address...${NC}"
                sleep 2
                mining_key=$(./target/release/poscan-consensus generate-mining-key --base-path "$BASE_PATH" --chain mainnetSpecRaw.json)
                echo $mining_key
                memo_seed=$(echo "$mining_key" | grep "Secret seed" | cut -d ':' -f 2-)
                echo -e "${Y}Memo_Seed: $memo_seed${NC}"
                uri_seed=$(./target/release/poscan-consensus import-mining-key "$memo_seed" --base-path "$BASE_PATH" --chain mainnetSpecRaw.json)
                public_key=$(echo "$uri_seed" | grep "Public key" | cut -d ':' -f 2-)
                echo -e "${Y}Public_key: $public_key${NC}"
                seeder=$(./target/release/poscan-consensus key inspect --scheme sr25519 "$memo_seed")
                grandpa_key=$(echo "$seeder" | grep "Secret seed" | cut -d ':' -f 2-)
                echo -e "${Y}Inserting Grandpa key into the keystore${NC}"
                grandpa=$(./target/release/poscan-consensus key insert --base-path ~/3dp-chain/ --chain mainnetSpecRaw.json --scheme Ed25519 --suri "$grandpa_key" --key-type gran)
                echo -e "${G}Grandpa key inserted into the keystore${NC}"
                sleep 2
            else
                read -p "Enter memo seed: " memo_seed
                seeder=$(./target/release/poscan-consensus key inspect --scheme sr25519 "$memo_seed")
                grandpa_key=$(echo "$seeder" | grep "Secret seed" | cut -d ':' -f 2-)
                uri_seed=$(./target/release/poscan-consensus import-mining-key "$memo_seed" --base-path "$BASE_PATH" --chain mainnetSpecRaw.json)
                public_key=$(echo "$uri_seed" | grep "Public key" | cut -d ':' -f 2-)
                echo -e "${Y}Inserting Grandpa key into the keystore${NC}"
                grandpa=$(./target/release/poscan-consensus key insert --base-path ~/3dp-chain/ --chain mainnetSpecRaw.json --scheme Ed25519 --suri "$grandpa_key" --key-type gran)
                echo -e "${G}Grandpa key inserted into the keystore${NC}"
            fi
            # check path of keystore-a
            log_file="miner_output.log"
            if [ $(ls -lat $BASE_PATH/chains/3dpass/keystore/ | wc -l) -ge 2 ]; then
                DEFAULT_MINER_PATH="${PWD}"
                DEFAULT_INTERVAL="1"
                echo -e "${Y} If you leave empty it will be set to default path (default: ${DEFAULT_MINER_PATH})${NC}"
                read -p "Enter path to the miner.js file(default: ${DEFAULT_MINER_PATH}): " miner_path
                echo -e "${Y}If you leave interval empty it will be set to default (default: ${DEFAULT_INTERVAL})${NC}"
                read -p "Enter interval: " interval
                if [ -z "$miner_path" ]; then
                        miner_path="$DEFAULT_MINER_PATH"
                fi
                if [ -z "$interval" ]; then
                        interval="$DEFAULT_INTERVAL"
                fi
                screen -S miner -m -d sh -c "cd $miner_path && npm update && node miner.js --interval $interval > $log_file 2>&1"
                echo -e "${G}Miner started you can check log on miner path ${BASE_PATH} in file: miner_output.log${NC}"

                # Checking is `node miner.js` started ok.
                if [ $? -ne 0 ]; then
                    echo -e "${R}Error on starting miner:${NC}"
                    cat $log_file
                fi
            else
                echo -e "${R}Miner can not be executed because missing parameters in keystore.${NC}"
            fi

            # Pokreni poscan-consensus s ostalim parametrima
            read -p "Enter number of threads for your node (example: 4): " threads_num
            echo -e "${G} Your node will consume $threads_num threads.${NC}"
            read -p "Enter name for your node which will be showed up on telemetry (example: my_node): " MyNodeName
            echo -e "${G} Your node will be displayed with name: $MyNodeName${NC}"
            screen -S node -m -d ./target/release/poscan-consensus --base-path ~/3dp-chain/ --chain mainnetSpecRaw.json --name $MyNodeName --validator --telemetry-url "wss://submit.telemetry.3dpass.org/submit 0" --author $public_key --threads $threads_num --no-mdns
            echo -e "${G}your node is started you can check it via command screen -r node to exit from the screen CTRL + A + D${NC}"
            echo -e "${Y}If you find this script useful, please consider making a donation to the following address: d1H1j9SGoMcJge45CNS81ey4GhMN8jqjte1fbNMgUSBW6Zv4f. Best regards, Wlink-NET${NC}"
        else
            echo -e "${R}It is not possible to start the poscan-consensus. Check the installation.${NC}"
        fi
        ;;
        2)
            # Pool node logic
            if [ -d "pass3d-pool" ]; then
                echo -e "${Y}pass3d-pool repo already exist.${NC}"
            else
                git clone https://github.com/3Dpass/pass3d-pool.git
            fi
            # Enter pass3d-pool folder and execute cargo build release
            cd pass3d-pool
            source $HOME/.cargo/env
            rustup update nightly
            rustup target add wasm32-unknown-unknown --toolchain nightly
            git pull
            cargo build --release

            #download miner
            if [ -d "miner" ]; then
                echo -e "${Y}miner repo already exist.${NC}"
            else
                git clone https://github.com/3Dpass/3DP.git miner
            fi
            # Run poscan-consensus if the installation is successful
            if [ -f "target/release/pass3d-pool" ]; then
                BASE_PATH="$HOME/pass3d-pool/"
                echo -e "${G}Successfully installed. Running pass3d-pool...${NC}"
                sleep 2
                if [ ! -f "miner/target/release/poscan-consensus" ]; then
                echo -e "${Y}Preparing to build binary poscan-consensus${NC}"
                cd miner
                git pull
                cargo build --release
                echo -e "${G}Extraction done and ready for use poscan-consensus for getting private_key(hex)${NC}"
                cd ..
                else
                    echo -e "${G}poscan-consensus file exist and we do not need to build it again${NC}"
                fi
                read -p "Enter your P3D address: " address
                read -p "Enter your memo_seed: " memo_seed
                seed=$(./miner/target/release/poscan-consensus key inspect --scheme sr25519 "$memo_seed")
                private_key=$(echo "$seed" | grep "Secret seed" | cut -d ':' -f 2-)
                echo -e "${G} Your pass3d-node will be started with address: $address${NC}"
                echo -e "${G} Your pass3d-node will be started with key: $private_key${NC}"
                screen -S pass3d-pool -m -d ./target/release/pass3d-pool --algo grid2d_v2 --pool-id d1DrnnYYFwynxpnZJork1TB8spm26AWaLPo7u9NukFQNSkoiK --member-id $address --url http://3dpool.cryptohood.org:9933/ --threads 32 --key $private_key
                echo -e "${G}your pass3d-pool is started you can check it via command screen -r pass3d-pool, to exit from the screen CTRL + A + D${NC}"
                log_file="miner_output.log"
                if [[ -n "$address" && -n "$private_key" ]]; then
		    DEFAULT_INTERVAL="1"
                    echo -e "${Y}If you leave interval empty it will be set to default (default: ${DEFAULT_INTERVAL})${NC}"
		    read -p "Enter interval: " interval
		    if [ -z "$interval" ]; then
                        interval="$DEFAULT_INTERVAL"
                    fi
                    screen -S miner -m -d sh -c "cd miner && npm update && node miner.js --interval $interval --port 9833 > $log_file 2>&1"
                    echo -e "${G}Miner started you can check log on miner path "${BASE_PATH}miner" in file: miner_output.log${NC}"
                    echo -e "${Y}If you find this script useful, please consider making a donation to the following address: d1H1j9SGoMcJge45CNS81ey4GhMN8jqjte1fbNMgUSBW6Zv4f. Best regards, Wlink-NET${NC}"
                    cd ..
                    # Checking is `node miner.js` started ok.
                    if [ $? -ne 0 ]; then
                    echo -e "${R}Error on starting miner:${NC}"
                    cat $log_file
                    fi
                else
                    echo -e "${R}Miner can not be executed because missing parameters in keystore.${NC}"
                fi
            else
                echo -e "${R}It is not possible to start the poscan-consensus. Check the installation.${NC}"
            fi
            ;;
        *)
            echo -e "${R}Invalid choice. Please choose either 1 or 2.${NC}"
            exit 1
            ;;
    esac
