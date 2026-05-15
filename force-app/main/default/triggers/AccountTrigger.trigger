/*
AccountTrigger Overview

This trigger performs several operations on the Account object during its insertion. Depending on the values and conditions of the newly created Account, this trigger can:

*/
trigger AccountTrigger on Account  (before insert, after insert)  {

    // Create an instance of the handler class to manage the logic
    AccountHelper acctHelper = new AccountHelper();
    acctHelper.run();

}