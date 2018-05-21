 pragma solidity ^0.4.15;

/// @title ERC20 Standard Interface
contract ERC20 {
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
  function totalSupply() external constant returns (uint256 supply) {}
  function balanceOf(address _owner) external constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) external returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {}
  function approve(address _spender, uint256 _value) external returns (bool success) {}
  function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {}
}

contract LoggingErrors {
  event LogErrorString(string errorString);

  /// @dev Default error to simply log the error message and return
  function error(string _errorMessage) internal returns(bool) {
    LogErrorString(_errorMessage);
    return false;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract envCoin is ERC20, LoggingErrors {
    using SafeMath for uint256;
    string public constant symbol = 'CCT';
    string public constant name = 'Carbon Credit Token';
    uint public constant decimals = 5;
    uint256 public totalSupply_;
    mapping (address => uint256) public balances_;
    mapping (address => business) public _businesses;
    mapping(address => mapping (address => uint256)) public allowed_;
    address public owner_;
    mapping (address => bool) public type_;
    uint256 revenueRatio = 150000;
    uint256 CO2Ratio = 1;
    uint256 SO2Ratio = 130;
    uint256 NOxRatio = 10000;
    uint256 otherDamagesRatio = 200000;

    struct business{
        string companyName_;
        bool hasCompany_;
        uint256 revenue_;
        uint256 totalBurned_;
        uint256 envIndex_;
        uint256 totalRevenue_;
        uint256 amountDue_;
        uint256 balances_;
        bool verified_;
        uint256 totalCO2;
        uint256 totalSO2;
        uint256 totalNOx;
        uint256 otherDamage_;

    }

//companies verify that they exist in the webapp and get stored here
    function applyBusiness(string _companyName){
        _businesses[msg.sender].companyName_ = _companyName;
        _businesses[msg.sender].hasCompany_ = true;
    }

// companies permitted to submit their revenue
    function submitRevenue(uint256 _revenue) external returns (bool){
        if (_businesses[msg.sender].hasCompany_){
            _businesses[msg.sender].revenue_ = _revenue;
        }
    }

//for arbitrator to ensure that the most recent application was appropriat
    function approveRevenue(bool verifyAll, address _companyName) external returns (bool){
        if(msg.sender == owner_){
            if(verifyAll){
                _businesses[_companyName].verified_ = verifyAll;
                _businesses[_companyName].totalRevenue_ += _businesses[_companyName].revenue_;
            }
        }
    return true;
    }

//companies redeem the funds based on their revenue, and the temporary revenue_ variable is cleared
    function getFunds(bool takeFunds) external{
        address company = msg.sender;
        if(_businesses[company].verified_ && _businesses[company].hasCompany_){
            _businesses[company].balances_ += _businesses[company].revenue_.div(revenueRatio);
            totalSupply_ += _businesses[company].revenue_.div(revenueRatio);
            _businesses[company].revenue_ = 0;
            _businesses[company].verified_ = false;
        }
    }

    function checkDues(uint256 CO2, uint256 SO2, uint256 NOx, uint256  other){
        uint due;
        address company = msg.sender;
        if (_businesses[company].hasCompany_){
            due += CO2.mul(CO2Ratio);
            due += SO2.mul(SO2Ratio);
            due += NOx.mul(NOxRatio);
            _businesses[company].totalCO2 += CO2;
            _businesses[company].totalSO2 += SO2;
            _businesses[company].totalNOx += NOx;
            _businesses[company].otherDamage_ += other;
            
        _businesses[company].amountDue_ += due;
        }
    }
    
    function payDues(bool ready, uint256 paying){
        address company = msg.sender;
        if (_businesses[company].hasCompany_){
            if (_businesses[company].balances_ >= paying){
                _businesses[company].balances_ -=paying ;
                totalSupply_ -= paying;
            }
        }
    }
    
    
  event LogTokensMinted(address indexed _to, uint256 value, uint256 totalSupply);
  /// @dev CONSTRUCTOR - set owner account
  function envCoin() {
    owner_ = msg.sender;
  }

    
// typical functionality of ERC20
    /// @dev Mint tokens and allocate them to the specified user.
    function mint (address _to, uint _value) external returns (bool) {
        if (msg.sender != owner_)
          return error('msg.sender != owner, Token.mint()');
        if (_value <= 0)
          return error('Cannot mint a value of <= 0, Token.mint()');
            // Can't mint to address(0)
        if (_to == address(0))
          return error('Cannot mint tokens to address(0), Token.mint()');
            // Update the total supply and balance of the _to user
            // Increase total supply my value
            // Increase _to in the balance mapping by the value
        totalSupply_ = totalSupply_.add(_value);
        balances_[_to] = balances_[_to].add(_value);
        
            // Logs
        LogTokensMinted(_to, _value, totalSupply_);
        Transfer(address(0), _to, _value);
    
    return true;
    }
    
    function approve(address _spender, uint256 _amount) external returns (bool) {
    if (_amount <= 0)
      return error('Can not approve an amount <= 0, Token.approve()');
    
    if (_amount > balances_[msg.sender])
      return error('Amount is greater than senders balance, Token.approve()');
    
    allowed_[msg.sender][_spender] = allowed_[msg.sender][_spender].add(_amount);
    
    return true;
    }
    
    /// @dev send `_value` token to `_to` from `msg.sender`
    function transfer (address _to, uint256 _value) external returns (bool){
        if (balances_[msg.sender] < _value)
          return error('Sender balance is insufficient, Token.transfer()');
            balances_[msg.sender] = balances_[msg.sender].sub(_value);
            balances_[_to] = balances_[_to].add(_value);
            Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /// @dev Transfer from one account to another on the from account's behalf
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool){
            // Can't transfer amount of 0!
        if (_amount <= 0)
          return error('Cannot transfer amount <= 0, Token.transferFrom()');
        
            // Confirm from has a sufficient balance
        if (_amount > balances_[_from])
          return error('From account has an insufficient balance, Token.transferFrom()');
        
            // Confirm sender has a sufficient allowance
        if (_amount > allowed_[_from][msg.sender])
          return error('msg.sender has insufficient allowance, Token.transferFrom()');
        
            // Move the funds from the _from balance to the _to balance
            // Decrease from's balance by value
            // Incease _to's balance by value
        balances_[_from] = balances_[_from].sub(_amount);
        balances_[_to] = balances_[_to].add(_amount);
        
            // Subtract the funds from the sender's allowance
        allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_amount);
        
            // Log
        Transfer(_from, _to, _amount);
        
            return true;
    }
    
    /// @return the allowance the owner gave the spender
    function allowance(address _owner, address _spender) external constant returns(uint256) {
    return allowed_[_owner][_spender];
    }
    
    /// @return The balance of the owner address
    function balanceOf(address _owner) external constant returns (uint256){
        return balances_[_owner];
      }
    
    /// @return total amount of tokens.
    function totalSupply ()  external constant returns (uint256){
    return totalSupply_;
    }
    

}
