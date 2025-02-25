import React, { useState, useEffect } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faCoins } from '@fortawesome/free-solid-svg-icons';
import { fetchNui } from '../utils/fetchNui';
import '../styles/App.css';
import { UserData } from './App';

interface DashboardProps {
  userData: UserData | null;
  onLoginRedirect: () => void;
  onLogout: () => void;
}

const Dashboard: React.FC<DashboardProps> = ({ userData, onLoginRedirect, onLogout }) => {
  const [cryptoAmount, setCryptoAmount] = useState<number | undefined>(undefined);
  const [balance, setBalance] = useState(userData?.balance || 0);
  const [bankBalance, setBankBalance] = useState(userData?.bankBalance || 0);
  const [cryptoValue, setCryptoValue] = useState(userData?.cryptoValue || 0);
  const [errorMessage, setErrorMessage] = useState('');
  const [successMessage, setSuccessMessage] = useState('');

  useEffect(() => {
    console.log('Dashboard component mounted');
    console.log('Initial userData:', userData);
    if (userData) {
      setBalance(userData.balance);
      setBankBalance(userData.bankBalance);
      setCryptoValue(userData.cryptoValue);
    }
  }, [userData]);

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        fetchNui('closeUI', {})
          .then(() => onLoginRedirect())
          .catch(error => console.error('Error invoking NUI callback:', error));
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [onLoginRedirect]);

  useEffect(() => {
    const updateBankBalance = async () => {
      try {
        const bankBalanceData = await fetchNui('getBankBalance', {});
        if (bankBalanceData && bankBalanceData.bankBalance !== undefined) {
          setBankBalance(bankBalanceData.bankBalance.toLocaleString('en-US', { minimumFractionDigits: 2 }));
        }
      } catch (error) {
        console.error('Error fetching bank balance:', error);
      }
    };

    const updateCryptoValue = async () => {
      try {
        const cryptoValueData = await fetchNui('getCurrentPrice');
        setCryptoValue(cryptoValueData.currentPrice);
      } catch (error) {
        console.error('Error fetching vCoin value:', error);
      }
    };

    const updateCryptoBalance = async () => {
      try {
        const cryptoBalanceData = await fetchNui('getCryptoBalance', {});
        if (cryptoBalanceData && cryptoBalanceData.cryptoBalance !== undefined) {
          setBalance(cryptoBalanceData.cryptoBalance);
        }
      } catch (error) {
        console.error('Error fetching vCoin balance:', error);
      }
    };

    const bankBalanceInterval = setInterval(updateBankBalance, 1000);
    const cryptoValueInterval = setInterval(updateCryptoValue, 1000);
    const cryptoBalanceInterval = setInterval(updateCryptoBalance, 1000);

    // Initial fetching
    updateBankBalance();
    updateCryptoValue();
    updateCryptoBalance();

    return () => {
      clearInterval(bankBalanceInterval);
      clearInterval(cryptoValueInterval);
      clearInterval(cryptoBalanceInterval);
    };
  }, []);

  const handleSell = async () => {
    const amount = cryptoAmount ?? 0;
    if (balance === 0) {
      setErrorMessage('You do not have any vCoins to sell.');
      setTimeout(() => setErrorMessage(''), 4000);
      return;
    }
    if (amount <= 0) {
      setErrorMessage('Please enter a number greater than 0.');
      setTimeout(() => setErrorMessage(''), 4000);
      return;
    }
    if (amount > balance) {
      setErrorMessage('You cannot sell more vCoins than you have.');
      setTimeout(() => setErrorMessage(''), 4000);
      return;
    }

    try {
      const sellResponse = await fetchNui('sellCrypto', { amount });
      console.log('Sell Response:', JSON.stringify(sellResponse));
      if (sellResponse && sellResponse.success) {
        setBalance(sellResponse.newBalance);
        if (sellResponse.newBankBalance !== undefined) {
          setBankBalance(sellResponse.newBankBalance.toLocaleString('en-US', { minimumFractionDigits: 2 }));
        }
        setCryptoAmount(undefined);
        setCryptoValue(sellResponse.cryptoValue);
        setErrorMessage(''); // Clear error message on successful sell.
        setSuccessMessage(`Successfully sold ${amount} vCoins for $${(cryptoValue * amount).toFixed(2)}`);
        setTimeout(() => setSuccessMessage(''), 4000);
      } else {
        setErrorMessage('Failed to sell crypto');
        setTimeout(() => setErrorMessage(''), 4000);
        console.error('Failed to sell crypto:', JSON.stringify(sellResponse));
      }
    } catch (error) {
      setErrorMessage('Error selling crypto');
      setTimeout(() => setErrorMessage(''), 4000);
      console.error('Error selling crypto:', error);
    }
  };

  return (
    <div className="centered-container">
      <div className="card">
        <div className="dashboard">
          <FontAwesomeIcon icon={faCoins} size="4x" className="vcoins-icon" />
          <h2>You Have</h2>
          <h3>x{balance} vCoins</h3>
          <hr />
          <h2>vCoin Worth</h2>
          <h3>${cryptoValue}</h3>
          <hr />
          <h2>Bank Balance</h2>
          <h3>${bankBalance}</h3>
          <input
            className="sell-input"
            type="number"
            step="0.01"
            placeholder="Amount to Sell"
            value={cryptoAmount === undefined ? '' : cryptoAmount}
            onChange={(e) => setCryptoAmount(parseFloat(e.target.value))}
          />
          {errorMessage && <p className="error-message">{errorMessage}</p>}
          {successMessage && <p className="success-message">{successMessage}</p>}
          <button className="sell" onClick={handleSell}>Sell</button>
          <button className="logout" onClick={onLogout}>Logout</button>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
