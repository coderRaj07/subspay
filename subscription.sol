// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract SubscriptionContract {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    address private owner;
    IERC20 immutable tokenAddress;
    Counters.Counter private subscriberCount;

    enum SubscriptionType {
        None,
        Silver,
        Gold,
        Premium
    }

    struct Subscription {
        SubscriptionType subscriptionType;
        // uint256 duration;
        // uint256 price;
        uint256 startTime;
    }

    // struct User {
    //     uint256 credits;
    //     Subscription subscription;
    // }

    mapping(address => Subscription) public subscriberDetails;
    // mapping(address => User) public users;
    mapping(SubscriptionType => uint256) public durationByType;
    mapping(SubscriptionType => uint256) public priceByType;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function."
        );
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = IERC20(_tokenAddress);
        subscriberCount.increment();

        durationByType[SubscriptionType.Silver] = 15 days;
        durationByType[SubscriptionType.Gold] = 30 days;
        durationByType[SubscriptionType.Premium] = 60 days;

        priceByType[SubscriptionType.Silver] = 0.001 ether; // 0.001 MATIC
        priceByType[SubscriptionType.Gold] = 0.01 ether; // 0.01 MATIC
        priceByType[SubscriptionType.Premium] = 0.1 ether; // 0.1 MATIC
    }

    function setSubscriptionType(
        SubscriptionType subscriptionType,
        uint256 duration,
        uint256 price
    ) external onlyOwner {
        require(duration > 0, "Invalid subscription duration.");
        require(price > 0, "Invalid subscription price.");

        durationByType[subscriptionType] = duration;
        priceByType[subscriptionType] = price;
    }

    function buySubscription(SubscriptionType subscriptionType) external {
        require(
            subscriptionType != SubscriptionType.None,
            "Invalid subscription type."
        );
        uint256 duration = durationByType[subscriberDetails[msg.sender].subscriptionType];
        uint256 endTime = subscriberDetails[msg.sender].startTime.add(duration);
        require(endTime < block.timestamp, "Subscription not ended!");
        require(
            users[msg.sender].subscription.subscriptionType ==
                SubscriptionType.None,
            "Already subscribed."
        );
        require(
            users[msg.sender].credits >= priceByType[subscriptionType],
            "Insufficient credits."
        );

        Subscription memory subscription;
        subscription.subscriptionType = subscriptionType;
        subscription.duration = durationByType[subscriptionType];
        subscription.price = priceByType[subscriptionType];
        subscription.startTime = block.timestamp;

        subscriberCount.increment();

        users[msg.sender].subscription = subscription;
        users[msg.sender].credits -= subscription.price;
    }

    function cancelSubscription() external {
        require(
            users[msg.sender].subscription.subscriptionType !=
                SubscriptionType.None,
            "No active subscription."
        );

        Subscription memory subscription = users[msg.sender].subscription;
        uint256 remainingTime = block.timestamp - subscription.startTime;

        // Calculate the credits to be refunded for the remaining time
        uint256 refundAmount = (remainingTime * subscription.price) /
            subscription.duration;

        users[msg.sender].subscription = Subscription(
            SubscriptionType.None,
            0,
            0,
            0
        );
        users[msg.sender].credits += refundAmount;
    }

    function getSubscriberDetails(
        address userAddress
    )
        external
        view
        returns (
            SubscriptionType subscriptionType,
            uint256 duration,
            uint256 price,
            uint256 startTime
        )
    {
        require(userAddress != address(0), "Invalid user address.");

        Subscription memory subscription = users[userAddress].subscription;
        subscriptionType = subscription.subscriptionType;
        duration = subscription.duration;
        price = subscription.price;
        startTime = subscription.startTime;
    }

    function getSubscriptionType(
        SubscriptionType subscriptionType
    ) external view returns (uint256 duration, uint256 price) {
        duration = durationByType[subscriptionType];
        price = priceByType[subscriptionType];
    }
}