# Digital Will Contract

A smart contract that enables users to create digital wills on the Stacks blockchain. The contract allows:

- Setting up a will with multiple beneficiaries and percentage-based inheritance shares
- Recording activity to prevent premature execution
- Claiming inheritance after the specified delay period has passed since last activity
- Checking will details and claim status

## Features

### Multiple Beneficiaries
- Support for up to 10 beneficiaries per will
- Percentage-based inheritance shares (must total 100%)
- Each beneficiary can claim their share independently
- Protection against duplicate beneficiary entries

### Security Features
- Activity tracking to prevent premature execution
- Independent claim tracking per beneficiary
- Share validation during will creation
- Inheritance delay period customization
- Validation to prevent duplicate beneficiary entries in the same will

The contract ensures that inheritance can only be claimed by designated beneficiaries after the owner has been inactive for the specified period, with each beneficiary receiving their correct percentage share of the total amount.

## Recent Updates
- Added validation to prevent duplicate beneficiaries in the same will
- Improved beneficiary lookup logic for better efficiency
- Enhanced error handling for invalid will configurations
