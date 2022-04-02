const { assert } = require('chai')

const TestNFT = artifacts.require('./TestNFT.sol')
require('web3')
require('chai')
  .use(require('chai-as-promised'))
  .should()

contract('Test NFT', (accounts) => {
    let token
    let account = web3.eth.getAccounts();
    before(async () => {
        token = await TestNFT.deployed()
    })
    describe('deployment', async () => {
         it('deploys successfully', async () => {            
            const address = token.address
            assert.notEqual(address, 0x0)
            assert.notEqual(address, '')
            assert.notEqual(address, null)
            assert.notEqual(address, undefined)
         }) 
         it('has a name', async () => {
            const name = await token.name()
            assert.equal(name, "TestNFT")           
         })
         it('has a symbol', async () => {
            const symbol = await token.symbol()
            assert.equal(symbol, "TNFT")           
         })    
    })
    describe('token distribution', async () => {
      
       // let sig = await web3.eth.sign(web3.utils.sha3("whitelist"), accounts[0])
       // console.log(`Signature${sig}`)
        let result
        it('place Order', async () => {
          await token.toggleMinting()
          //await token.toggleOnlyWhitelisted()
          await token.setMintPrice(web3.utils.toWei('0.02','ether'))
          result = await token.getMintPrice()
          console.log(`Mint Price${result}`)
          assert.equal(result, web3.utils.toWei('0.02','ether'))
          //console.log(result)
          await token.setBaseURI('https://www.cryptopixel.com/nft/json/')
          
          result = await token.placeOrder(3, web3.utils.toWei('0.003','ether'), {from:accounts[0], value:web3.utils.toWei('0.066','ether'), gasPrice: 5000000 , gas: 5000000 })
         // console.log(`Place${result}`)
          result = await token.tokenURI(0)
          console.log(`Place${result}`)
          assert.equal(result, 'https://www.cryptopixel.com/nft/json/0.json' )

          result = await token.totalSupply()
          console.log(`Supply${result}`)
          assert.equal(result, 3)
          
          result = await token.getBalance()
          console.log(`Balance${result}`)
        
        })
        
    
    })
    
    describe('NFT Place Order Change Price add Fees', async () => {
      let result
     // let sig = await web3.eth.sign("whitelist", accounts[0])
      //console.log(`Signature${sig}`)
      it('place Order', async () => {
        await token.setMintPrice(web3.utils.toWei('0.01','ether'))
        result = await token.getMintPrice()
        console.log(`Mint Price${result}`)
        assert.equal(result, web3.utils.toWei('0.01','ether'))
        //console.log(result)
        await token.setFeePrice(web3.utils.toWei('0.01','ether'))
        result = await token.getFeePrice()
        console.log(`Fee Price${result}`)
        assert.equal(result, web3.utils.toWei('0.01','ether'))
        
        result = await token.k
       // console.log(`Place${result}`)
        result = await token.tokenURI(3)
        console.log(`Place${result}`)
        assert.equal(result, 'https://www.cryptopixel.com/nft/json/3.json' )

        result = await token.totalSupply()
        console.log(`Supply${result}`)
        assert.equal(result, 4) 

        result = await token.getBalance()
        console.log(`Balance${result}`)
      
      })
    })
    describe('NFT Place Order Change Price add Fees', async () => {
      let result
      it('place Order', async () => {
        await token.withdraw()
        result = await token.getBalance()
        console.log(`Balance${result}`)

      })
    })
    describe('Owner Mint From Reserve', async () => {
      let result
      it('place Order', async () => {
        await token.ownerMintFromReserve(accounts[0], 10)
        result = await token.addressMintedBalance(accounts[0])
        console.log(`Minted Balance${result}`)

        //await token.balanceOf(accounts[0])
        result = await token.balanceOf(accounts[0])
        console.log(`Balance${result}`)

      })
    })
    
    
})