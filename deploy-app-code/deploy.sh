echo "Removing function zip"
rm -rf ./zip/*.zip

echo "Removing function binary"
rm -rf ./_golang/cmd/func/main.exe
rm -rf ./_golang/azure_functions/deploy/main.exe

echo "Building function binary"
cd ./_golang/cmd/func && GOOS=windows GOARCH=amd64 go build -o main.exe *.go && cd ../../../

echo "Copying function binary to azure functions"
cp ./_golang/cmd/func/main.exe ./_golang/azure_functions/deploy/

terraform init

terraform apply -auto-approve
