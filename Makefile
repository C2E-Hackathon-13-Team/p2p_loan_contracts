redeploy:
	@npx hardhat compile
	@npx hardhat ignition deploy ./ignition/modules/Loan.ts --network sepolia
t:
	@npx hardhat test --network sepolia  ./test/Loan.ts
