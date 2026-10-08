// Usage: node check-in.mjs <deadline offset in seconds from now>, e.g. 60 (open) or -60 (closed).
// Sends one check_in to devnet with skipPreflight, so a rejected check-in also lands and shows on Explorer.
//
// Environment (all optional):
//   PROGRAM_ID  your deployed program (default: the reference deployment from dry run 001)
//   KEYPAIR     payer keypair file (default: ~/.config/solana/id.json); read, never printed
//   RPC_URL     default https://api.devnet.solana.com
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { Connection, Keypair, PublicKey, Transaction, TransactionInstruction } from "@solana/web3.js";

const PROGRAM_ID = new PublicKey(process.env.PROGRAM_ID ?? "F7zvaAQ6ydv25hBUnh7tFkMaH7ixj4Y9r8XS7dxDamuF");
const KEYPAIR = process.env.KEYPAIR ?? `${homedir()}/.config/solana/id.json`;
const RPC_URL = process.env.RPC_URL ?? "https://api.devnet.solana.com";

const offset = BigInt(process.argv[2] ?? "60");
const payer = Keypair.fromSecretKey(Uint8Array.from(JSON.parse(readFileSync(KEYPAIR, "utf8"))));
const connection = new Connection(RPC_URL, "confirmed");

// Instruction data: the deadline, i64 little-endian unix seconds. No accounts.
const deadline = BigInt(Math.floor(Date.now() / 1000)) + offset;
const data = Buffer.alloc(8);
data.writeBigInt64LE(deadline);
const ix = new TransactionInstruction({ programId: PROGRAM_ID, keys: [], data });

const tx = new Transaction().add(ix);
tx.feePayer = payer.publicKey;
const { blockhash, lastValidBlockHeight } = await connection.getLatestBlockhash();
tx.recentBlockhash = blockhash;
tx.sign(payer);
const sig = await connection.sendRawTransaction(tx.serialize(), { skipPreflight: true });
const res = await connection.confirmTransaction({ signature: sig, blockhash, lastValidBlockHeight });
console.log(`program=${PROGRAM_ID.toBase58()} deadline=${deadline} err=${JSON.stringify(res.value.err)}`);
console.log(`https://explorer.solana.com/tx/${sig}?cluster=devnet`);
