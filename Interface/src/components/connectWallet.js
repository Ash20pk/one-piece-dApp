import React, { useEffect, useState, createContext, useContext } from 'react';
import Web3 from 'web3';
import nftABI from '../contract/OnePieceMint.json'

// Create a context for Web3
const Web3Context = createContext();

// Custom hook to use the Web3 context
export const useWeb3 = () => useContext(Web3Context);

export function ConnectWallet({ children }) {
  const [web3, setWeb3] = useState(null);
  const [account, setAccount] = useState(null);
  const [connected, setConnected] = useState(false);
  const [nftcontract, setNftcontract] = useState(null);

  useEffect(() => {
    if (window.ethereum) {
      const web3Instance = new Web3(window.ethereum);
      setWeb3(web3Instance);
    }
  }, []);

  const nftContractAddress = "0xcB111FDedE11049744c0edebde2f4C012f76CA5C";


  const connectWallet = async () => {
      try {
        await window.ethereum.request({ method: "eth_requestAccounts" });
        const accounts = await web3.eth.getAccounts();
        const account = accounts[0];
        const currentChainId = await window.ethereum.request({
          method: 'eth_chainId',
        });
        if (currentChainId !== '0x13881') { // Assuming '0x13881' is the chain ID for Polygon Mumbai Testnet
          alert("Connect to Polygon Mumbai Testnet");
          return;
        }
        const instance = new web3.eth.Contract(nftABI.abi, nftContractAddress);
        setNftcontract(instance);
        console.log(account);
        setAccount(account);
        setConnected(true);
      } catch (error) {
        console.error(error);
      }
    }

  const disconnectWallet = () => {
    setAccount(null);
    setConnected(false);
  };

  return (
    <Web3Context.Provider value={{ web3, account, disconnectWallet, connectWallet, connected, nftcontract }}>
      <div>
        {children}
      </div>
    </Web3Context.Provider>
  );
}