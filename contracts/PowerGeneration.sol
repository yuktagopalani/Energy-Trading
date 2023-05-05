//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract PowerGeneration{
    address private administrator;
    uint256 numberOfUsers=0; 
    struct User {
        uint256 userID;
        string name;
        address payable userAddress;
        uint256 powerConsumption;
        uint256 powerProduction;
        bool isProducer;
        bool isConsumer;
    }

    struct DistancePair{
        uint256 dist;
        uint h1;
        uint h2;
    }

    struct Trade{
        uint256 dist;
        uint256 energyExchange;
        uint byr;
        uint sllr;
    }

   
    uint256[][] distance=[[0,2,3,10,11,24,5], 
                          [2,0,5,11,10,5,4],
                          [3,5,0,10,11,25,24],
                          [10,11,10,0,2,5,4],
                          [11,10,11,2,0,2,3],
                          [24,5,25,5,2,0,4],
                          [5,4,24,4,3,4,0]];
   
    mapping(uint256 => User) public user;
    mapping(address => uint256) public userID;
    uint256[] public sellers;
    uint256[] public buyers;
     mapping (uint256 => uint256) netProduction;
     mapping (uint256 => uint256) netConsumption;
   
    constructor() {
        administrator = msg.sender;
    }

    function quickSort(DistancePair[] memory arr, int256 left, int256 right) pure public{
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)].dist;
        while (i <= j) {
            while (arr[uint256(i)].dist < pivot) i++;
            while (pivot < arr[uint256(j)].dist) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    function sort(DistancePair[] memory data) public pure returns (DistancePair[] memory) {
        uint256 datasize=data.length;
        quickSort(data, int256(0), int256(data.length - 1));
        return data;
    }

    function registerUser(uint256 id, address payable addr, string memory _name) public {
        user[id] = User({
            userID: id,
            userAddress: addr,
            name: _name,
            powerConsumption: 0,
            powerProduction: 0,
            isProducer: false,
            isConsumer: false
        });
        userID[addr]=id;
        numberOfUsers++;
    }

    function generatePower(uint256 _value) public {
        uint256 id = userID[msg.sender];
        user[id].powerProduction += _value;
        if(user[id].powerProduction > user[id].powerConsumption){
            user[id].isProducer = true;
            user[id].isConsumer = false;
        }
        else{
            user[id].isProducer = false;
            user[id].isConsumer = true;
        }
    }

    function consumePower(uint256 _value) public{
        uint256 id = userID[msg.sender];
        user[id].powerConsumption += _value;
        if(user[id].powerProduction > user[id].powerConsumption){
            user[id].isProducer = true;
            user[id].isConsumer = false;
        }
        else{
            user[id].isProducer = false;
            user[id].isConsumer = true;
        }
    }
    DistancePair[] public distributionVector;//{dist,{buyers,seller}}
    Trade[] public finalPairs;//{energy exchanged,{buyers,seller}}

    function calculateBestRoutes() public returns (Trade[] memory){
        for(uint i=0;i<numberOfUsers;i++){
            if(user[i].isProducer==true){
                sellers.push(i);
                netProduction[i]=user[i].powerProduction - user[i].powerConsumption;
            }
            else{
                buyers.push(i);
                netConsumption[i]=user[i].powerConsumption - user[i].powerProduction;
            }
        }

        uint256 noOfSellers=sellers.length;
        uint256 noOfBuyers=buyers.length;

        for(int i=0;uint256(i)< noOfSellers;++i){
            for(int j=0;uint256(j)<noOfBuyers;++j){   
                uint256 indxh1=sellers[uint256(i)];
                uint256 indxh2=buyers[uint256(j)];
                DistancePair memory temp= DistancePair({
                    h1: indxh1,
                    h2: indxh2,
                    dist: distance[indxh1][indxh2]
                });
            
                distributionVector.push(temp);
            }
        }

        DistancePair[] memory dv=sort(distributionVector);

        for(int i=0;uint256(i)<distributionVector.length;++i){
            //now for each check how much can we take  of selll and push in a array
            uint256 currDist=dv[uint256(i)].dist;
            uint256 currSellerIndx=dv[uint256(i)].h1;//index of seller here
            uint256 currBuyerIndx=dv[uint256(i)].h2;//index of buyer here
            if(netConsumption[currBuyerIndx]==0  || netProduction[currSellerIndx]==0) 
                continue;

            if(netConsumption[currBuyerIndx]>netProduction[currSellerIndx]){
                Trade memory temp= Trade({
                    dist: currDist,
                    energyExchange: netProduction[currSellerIndx],
                    byr: currBuyerIndx,
                    sllr: currSellerIndx
                });
                netConsumption[currBuyerIndx]-=netProduction[currSellerIndx];
                netProduction[currSellerIndx]=0;
                finalPairs.push(temp);
            }else if(netConsumption[currBuyerIndx]<=netProduction[currSellerIndx]){
                Trade memory temp= Trade({
                    dist: currDist,
                    energyExchange: netConsumption[currBuyerIndx],
                    byr: currBuyerIndx,
                    sllr: currSellerIndx
                });
                netProduction[currSellerIndx]-=netConsumption[currBuyerIndx];
                netConsumption[currBuyerIndx]=0;
                finalPairs.push(temp);
            }
        }
        return finalPairs;
    }
}