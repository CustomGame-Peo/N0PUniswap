// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
 * x * y = k, k is const number
 * exchange token, x
 */

interface IExchange {
    function ethToTokenSwap(uint256 _minTokens) external payable;

    function ethToTokenTransfer(uint256 _minTokens, address _recipient) external payable;
}

interface IFactory {
    function getExchange(address _tokenAddress) external view returns (address);
}

contract Exchange is ERC20 {
    address public tokenAddress;
    address public factoryAddress;

    constructor(address _token) ERC20("fun", "funny") {
        require(_token != address(0), "invalid token address");

        tokenAddress = _token;
        factoryAddress = msg.sender;
    }

    function addLiquidity(uint256 _tokenAmount) public payable returns (uint256) {
        uint256 liquidity;
        if (getReserve() == 0) {
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), _tokenAmount);
            liquidity = address(this).balance;
            _mint(msg.sender, liquidity);
        } else {
            // eth amount before  get user send eth
            uint256 ethOldAmount = address(this).balance - msg.value;
            uint256 tokenOldAmount = getReserve();
            uint256 tokenExchangeAmount = msg.value * (ethOldAmount / tokenOldAmount);
            // _tokenAmount is me provider token amount,but tokenMintAmount is me provider eth can exchange token.
            // 如果tokenExchangeAmount小于_tokenAmount,那么这次添加流动性会破坏ETH和token的价格，所以ETH能换多少token，那么我们就传入多少token。
            // 流动性添加时候，不能影响价格，否则会让流动性提供者损失财产
            require(_tokenAmount >= tokenExchangeAmount, "insufficient token amount");
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), tokenExchangeAmount);
            // so we should award provider lp token
            liquidity = (IERC20(this).totalSupply() * msg.value) / ethOldAmount;
            _mint(msg.sender, liquidity);
        }
        return liquidity;
    }

    function burn(address sender, uint256 _amount) public {}

    function removeLiquidity(uint256 _amount) public payable returns (uint256, uint256) {
        require(_amount > 0, "invalid amount");
        uint256 ethAmount = (_amount * address(this).balance) / IERC20(this).totalSupply();
        uint256 tokenAmount = (_amount * getReserve()) / IERC20(this).totalSupply();
        burn(msg.sender, _amount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        payable(msg.sender).transfer(ethAmount);
        return (ethAmount, tokenAmount);
    }

    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getPrice(uint256 token1, uint256 token2) public pure returns (uint256) {
        return (token1 * 1000) / token2;
    }

    function getAmount(
        uint256 inputAmount,
        uint256 token1,
        uint256 token2
    ) public pure returns (uint256) {
        require(inputAmount > 0 && token2 > 0, "invalid reserves");
        // we take 0.1% fee
        uint256 inputAmountAfterFee = inputAmount * 99;
        uint256 numberator = inputAmountAfterFee * token2;
        uint256 denominator = (token1 * 100) + inputAmountAfterFee;
        return numberator / denominator;
    }

    function getETHAmount(uint256 _inputAmount) public view returns (uint256) {
        uint256 tokenReserve = getReserve();
        return getAmount(_inputAmount, address(this).balance, tokenReserve);
    }

    function getTokenAmount(uint256 _inputAmount) public view returns (uint256) {
        uint256 tokenReserve = getReserve();
        return getAmount(_inputAmount, tokenReserve, address(this).balance);
    }

    function ethToTokenSwap(uint256 _minToken) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokenBought = getAmount(msg.value, address(this).balance - msg.value, tokenReserve);
        require(tokenBought >= _minToken, "this price is too less");
        IERC20(tokenAddress).transfer(msg.sender, tokenBought);
    }

    function tokenToEthSwap(uint256 _tokenAmount, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(_tokenAmount, tokenReserve, address(this).balance);
        require(ethBought >= _minEth, "this price is too less");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);
        payable(msg.sender).transfer(ethBought);
    }

    function tokenToTokenSwap(
        uint256 _tokenSold,
        uint256 _minTokenBought,
        address _tokenAddress
    ) public {
        address exchange = IFactory(factoryAddress).getExchange(_tokenAddress);
        require(exchange != address(0), "invalid exchange address");
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(_tokenSold, tokenReserve, address(this).balance);
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);
        IExchange(exchange).ethToTokenSwap(_minTokenBought);
    }
}
