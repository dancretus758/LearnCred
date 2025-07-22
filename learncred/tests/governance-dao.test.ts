// governance-dao.test.ts
import { describe, it, expect, beforeEach } from "vitest"

type Proposal = {
  proposer: string
  description: string
  votesFor: number
  votesAgainst: number
  executed: boolean
  endBlock: number
}

const mockContract = {
  admin: "STADMIN000000000000000000000000000000000",
  proposals: new Map<number, Proposal>(),
  votes: new Map<string, boolean>(),
  proposalCounter: 0,
  currentBlock: 1000,

  onlyAdmin(caller: string) {
    return caller === this.admin
  },

  createProposal(caller: string, description: string, duration: number) {
    this.proposalCounter += 1
    this.proposals.set(this.proposalCounter, {
      proposer: caller,
      description,
      votesFor: 0,
      votesAgainst: 0,
      executed: false,
      endBlock: this.currentBlock + duration,
    })
    return { value: this.proposalCounter }
  },

  vote(caller: string, proposalId: number, support: boolean) {
    const proposal = this.proposals.get(proposalId)
    if (!proposal) return { error: 101 }
    if (this.currentBlock >= proposal.endBlock) return { error: 104 }

    const voteKey = `${proposalId}:${caller}`
    if (this.votes.has(voteKey)) return { error: 102 }

    this.votes.set(voteKey, support)
    if (support) proposal.votesFor += 1
    else proposal.votesAgainst += 1

    return { value: true }
  },

  executeProposal(proposalId: number) {
    const proposal = this.proposals.get(proposalId)
    if (!proposal) return { error: 101 }
    if (proposal.executed) return { error: 104 }
    if (proposal.votesFor < proposal.votesAgainst) return { error: 104 }

    proposal.executed = true
    return { value: true }
  },

  transferAdmin(caller: string, newAdmin: string) {
    if (!this.onlyAdmin(caller)) return { error: 100 }
    this.admin = newAdmin
    return { value: true }
  },

  hasVoted(proposalId: number, voter: string) {
    return this.votes.has(`${proposalId}:${voter}`)
  },

  getProposal(proposalId: number) {
    return this.proposals.get(proposalId)
  },
}

describe("Governance DAO Contract", () => {
  beforeEach(() => {
    mockContract.admin = "STADMIN000000000000000000000000000000000"
    mockContract.proposals = new Map()
    mockContract.votes = new Map()
    mockContract.proposalCounter = 0
    mockContract.currentBlock = 1000
  })

  it("should allow admin to create a proposal", () => {
    const result = mockContract.createProposal("STADMIN000000000000000000000000000000000", "Fund open-source", 100)
    expect(result.value).toBe(1)
    const proposal = mockContract.getProposal(1)
    expect(proposal?.description).toBe("Fund open-source")
  })

  it("should allow users to vote and prevent double voting", () => {
    mockContract.createProposal("STADMIN000000000000000000000000000000000", "Upgrade contract", 50)
    const vote1 = mockContract.vote("STUSER1", 1, true)
    expect(vote1).toEqual({ value: true })

    const vote2 = mockContract.vote("STUSER1", 1, false)
    expect(vote2).toEqual({ error: 102 }) // Already voted

    const proposal = mockContract.getProposal(1)
    expect(proposal?.votesFor).toBe(1)
    expect(proposal?.votesAgainst).toBe(0)
  })

  it("should reject votes after end block", () => {
    mockContract.createProposal("STADMIN000000000000000000000000000000000", "End proposal", 5)
    mockContract.currentBlock += 6
    const vote = mockContract.vote("STUSER1", 1, true)
    expect(vote).toEqual({ error: 104 })
  })

  it("should execute approved proposal", () => {
    mockContract.createProposal("STADMIN000000000000000000000000000000000", "Execute me", 10)
    mockContract.vote("STUSER1", 1, true)
    mockContract.vote("STUSER2", 1, true)

    const result = mockContract.executeProposal(1)
    expect(result).toEqual({ value: true })

    const proposal = mockContract.getProposal(1)
    expect(proposal?.executed).toBe(true)
  })

  it("should not execute rejected proposal", () => {
    mockContract.createProposal("STADMIN000000000000000000000000000000000", "Reject me", 10)
    mockContract.vote("STUSER1", 1, false)

    const result = mockContract.executeProposal(1)
    expect(result).toEqual({ error: 104 })
  })

  it("should allow admin transfer", () => {
    const result = mockContract.transferAdmin("STADMIN000000000000000000000000000000000", "STNEWADMIN")
    expect(result).toEqual({ value: true })
    expect(mockContract.admin).toBe("STNEWADMIN")
  })

  it("should block non-admin from transferring admin", () => {
    const result = mockContract.transferAdmin("STUSER1", "STNEWADMIN")
    expect(result).toEqual({ error: 100 })
  })
})
