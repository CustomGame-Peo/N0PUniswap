const { time, loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers")
const { ethers } = require("hardhat")
const { expect } = require("chai")
const toWei = (value) => ethers.parseEther(value.toString())

describe("Exchange", function () {
    let tokenFactory, token, exchangeFactory, exchange
    let user, provider
    beforeEach(async function deployExchange() {
        tokenFactory = await ethers.getContractFactory("Token")
        token = await tokenFactory.deploy("Test Token", "TEST", toWei(1000))

        exchangeFactory = await ethers.getContractFactory("Exchange")
        exchange = await exchangeFactory.deploy(token)

        user = await ethers.getSigners()
        provider = await ethers.provider
    })
    describe("addLiquidity", function () {
        it("adds liquidity function called...", async () => {
            await token.approve(exchange, toWei(500))
            await exchange.addLiquidity(toWei(2), { value: toWei(80) })
            expect(await provider.getBalance(exchange)).to.equal(toWei(80))
            expect(await exchange.getReserve()).to.equal(toWei(2))
        })
    })

    describe("getPrice", function () {
        it("getPrice function is normal...", async () => {
            expect(await exchange.getPrice(1000, 200)).to.equal(5000)
        })
    })

    describe("getAmount", function () {
        it("getAmount function is normal...", async () => {
            expect(await exchange.getAmount(100, 400, 800)).to.equal(44)
        })
    })

    describe("getETHAmount", function () {
        it("get ETH amount ...", async () => {
            await token.approve(exchange, toWei(500))
            await exchange.addLiquidity(toWei(0.0000000002), { value: toWei(0.0000000004) })

            const x = await exchange.getReserve()
            const y = await provider.getBalance(exchange)
            console.log(x.toString())
            console.log(y.toString())
            expect(await exchange.getETHAmount(5)).to.equal(100)
        })
    })

    describe("getTokenAmount", function () {
        it("get token amount...", async () => {
            expect(await exchange.getTokenAmount(50)).to.equal(100)
        })
    })

    describe("About Liquidty such", function () {
        it("add Liquidity", async () => {})
        it("remove Liquidity", async () => {})
    })

    describe("About swap such", function () {
        it("take 0.1% fee", async () => {})
        it("swap token to eth", async () => {})
    })
})
//1000000000000000000000
