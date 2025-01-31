import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can set up a will with multiple beneficiaries",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const owner = accounts.get('wallet_1')!;
        const beneficiary1 = accounts.get('wallet_2')!;
        const beneficiary2 = accounts.get('wallet_3')!;
        
        const block = chain.mineBlock([
            Tx.contractCall('digital-will', 'set-will', [
                types.list([
                    types.tuple({
                        beneficiary: types.principal(beneficiary1.address),
                        share: types.uint(60)
                    }),
                    types.tuple({
                        beneficiary: types.principal(beneficiary2.address),
                        share: types.uint(40)
                    })
                ]),
                types.uint(1000000),
                types.uint(144)
            ], owner.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
    },
});

Clarinet.test({
    name: "Fails when shares don't add up to 100",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const owner = accounts.get('wallet_1')!;
        const beneficiary1 = accounts.get('wallet_2')!;
        const beneficiary2 = accounts.get('wallet_3')!;
        
        const block = chain.mineBlock([
            Tx.contractCall('digital-will', 'set-will', [
                types.list([
                    types.tuple({
                        beneficiary: types.principal(beneficiary1.address),
                        share: types.uint(60)
                    }),
                    types.tuple({
                        beneficiary: types.principal(beneficiary2.address),
                        share: types.uint(30)
                    })
                ]),
                types.uint(1000000),
                types.uint(144)
            ], owner.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(105);
    },
});

Clarinet.test({
    name: "Can claim correct share amounts",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const owner = accounts.get('wallet_1')!;
        const beneficiary1 = accounts.get('wallet_2')!;
        const beneficiary2 = accounts.get('wallet_3')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('digital-will', 'set-will', [
                types.list([
                    types.tuple({
                        beneficiary: types.principal(beneficiary1.address),
                        share: types.uint(60)
                    }),
                    types.tuple({
                        beneficiary: types.principal(beneficiary2.address),
                        share: types.uint(40)
                    })
                ]),
                types.uint(1000000),
                types.uint(144)
            ], owner.address)
        ]);
        
        chain.mineEmptyBlockUntil(200);
        
        block = chain.mineBlock([
            Tx.contractCall('digital-will', 'claim-inheritance', [
                types.principal(owner.address)
            ], beneficiary1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        // TODO: Add balance assertion for 60% share
    },
});
