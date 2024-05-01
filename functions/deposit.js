const chainId = args[0]
const inputToken = args[1]
const inputTokenAmount = args[2]
const outputCTF = args[3]

const request = Functions.makeHttpRequest({
  url: "https://jsonplaceholder.typicode.com/posts",
  method: "POST",
})

const response = await request

if (response.error) throw Error("Failed To deposit")
const data = response["data"]

const mintAmount = 100e18 // data["mint_amount"];

if (mintAmount == 0 || mintAmount === undefined) throw Error("Invalid Mint Amount")

return Functions.encodeUint256(mintAmount)
