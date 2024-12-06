import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can set up a will",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const owner = accounts.get('wallet_1')!;
        const beneficiary = accounts.get('wallet_2')!;
        
        const block = chain.mineBlock([
            Tx.contractCall('digital-will', 'set-will', [
                types.principal(beneficiary.address),
                types.uint(1000000),
                types.uint(144)  // ~1 day in blocks
            ], owner.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
    },
});

Clarinet.test({
    name: "Cannot claim before delay period",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const owner = accounts.get('wallet_1')!;
        const beneficiary = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('digital-will', 'set-will', [
                types.principal(beneficiary.address),
                types.uint(1000000),
                types.uint(144)
            ], owner.address)
        ]);
        
        block = chain.mineBlock([
            Tx.contractCall('digital-will', 'claim-inheritance', [
                types.principal(owner.address)
            ], beneficiary.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(103);
    },
});

Clarinet.test({
    name: "Can record activity",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const owner = accounts.get('wallet_1')!;
        const beneficiary = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('digital-will', 'set-will', [
                types.principal(beneficiary.address),
                types.uint(1000000),
                types.uint(144)
            ], owner.address)
        ]);
        
        block = chain.mineBlock([
            Tx.contractCall('digital-will', 'record-activity', [], owner.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
    },
});
