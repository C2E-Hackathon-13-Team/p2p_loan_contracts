deploy-sepolia:
	@NODE_ENV=development npx hardhat compile
	@NODE_ENV=development npx hardhat ignition wipe chain-11155111 LockModule#Loan
	@NODE_ENV=development npx hardhat ignition deploy ./ignition/modules/Loan.ts --network sepolia
deploy-local:
	@NODE_ENV=local npx hardhat compile
	@NODE_ENV=local npx hardhat ignition deploy ./ignition/modules/Loan.ts --network local
t:
	@npx hardhat test --network sepolia  ./test/Loan.ts
