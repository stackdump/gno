// SPDX-License-Identifier: CC0-1.0
// Tanks & Taps (BSIP-72) — Petri-net reimplementation (full coverage)
// Package: metamodel  (namespace: tnt000)
//
// Models tanks (asset places), taps (withdrawal transitions), requirements
// (guard subnets), and attachments (meters, tap-opener, connect-authority).
// Also includes connection types and deposit path restriction guards.
//
// Version: v0
// Ports/Objects: "$asset", "$core", "$account", "$tank", "$meter", "$ctrl", "$quota", "$auth", "$time", "$hash", "$ticket"
//
// Notes on expressiveness:
// - Numeric flow limits are encoded with token multiplicity in $quota/$asset.
// - Minimum-level, time windows, and periodicity use gating places fed by an
//   external scheduler/clock ("$time") — exact read/inhibitor arcs noted in comments.
// - Authorized sources & restricted-asset checks modeled as $auth tokens produced
//   by off-chain or host-chain checks before firing guarded transitions.

package bsip072

import (
    "strings"
    mm "gno.land/p/labs/metamodel"
)

// ---------- Shared Types/Helpers ----------

type Record struct {
    Id          string
    Name        string
    Description string
    Model       *mm.Model
}

const (
    basePath = "/r/labs/bsip072"

    // Object ports (token types)
    Asset   = "$asset"   // fungible units held/flowing (tank's asset)
    Core    = "$core"    // chain core asset (for tank deposit)
    Account = "$account" // external account sink/source
    TankObj = "$tank"    // tank identity/authority token (optional binding)
    Meter   = "$meter"   // meter "tick" tokens (attachment)
    Ctrl    = "$ctrl"    // control/approval/documentation tokens
    Quota   = "$quota"   // quota/limit tokens (flow limits)
    Auth    = "$auth"    // authorization tokens (restricted assets / path auth)
    Time    = "$time"    // time/window tokens (periodic/time-lock)
    Hash    = "$hash"    // hash/preimage proof tokens
    Ticket  = "$ticket"  // ticket tokens (signed permission)
)

func getInt(opts map[string]any, key string, def int) int {
    if v, ok := opts[key]; ok {
        if vi, ok := v.(int); ok {
            return vi
        }
    }
    return def
}

// ---------- Registry of Patterns (one per BSIP item) ----------

var tntRegistry = []*Record{
    {Id: "tank_core", Name: "TNT_CoreTank", Description: "Tank with deposit, emergency destructor tap, and authorized source gate.", Model: TNT_CoreTank(nil)},

    // Requirements (tap guards)
    {Id: "tap_immediate_limit", Name: "TNT_Tap_ImmediateLimit", Description: "Immediate per-opening limit + documentation.", Model: TNT_Tap_ImmediateLimit(map[string]any{"limit": 10})},
    {Id: "tap_cumulative_limit", Name: "TNT_Tap_CumulativeLimit", Description: "Cumulative total limit.", Model: TNT_Tap_CumulativeLimit(map[string]any{"limitTotal": 100})},
    {Id: "tap_periodic_limit", Name: "TNT_Tap_PeriodicLimit", Description: "Periodic quota with clock reset.", Model: TNT_Tap_PeriodicLimit(map[string]any{"periodLimit": 50})},
    {Id: "tap_time_lock", Name: "TNT_Tap_TimeLock", Description: "Time windows (locked/unlocked).", Model: TNT_Tap_TimeLock(nil)},
    {Id: "tap_minimum_level", Name: "TNT_Tap_MinimumTankLevel", Description: "Reserve floor: cannot drain below minimum.", Model: TNT_Tap_MinimumTankLevel(map[string]any{"reserve": 20})},
    {Id: "tap_review", Name: "TNT_Tap_ReviewRequirement", Description: "Reviewer approval workflow.", Model: TNT_Tap_ReviewRequirement(nil)},
    {Id: "tap_documentation", Name: "TNT_Tap_Documentation", Description: "Documentation-only requirement.", Model: TNT_Tap_Documentation(nil)},
    {Id: "tap_delay", Name: "TNT_Tap_DelayRequirement", Description: "Delay with optional veto.", Model: TNT_Tap_DelayRequirement(nil)},
    {Id: "tap_hash_preimage", Name: "TNT_Tap_HashPreimage", Description: "Preimage proof requirement.", Model: TNT_Tap_HashPreimage(nil)},
    {Id: "tap_ticket", Name: "TNT_Tap_TicketRequirement", Description: "Signed ticket consumption with sequence.", Model: TNT_Tap_TicketRequirement(nil)},
    {Id: "tap_exchange_meter", Name: "TNT_Tap_ExchangeRequirement", Description: "Exchange limit driven by asset_flow_meter ticks.", Model: TNT_Tap_ExchangeRequirement(map[string]any{"releasePerTick": 1, "tickAmount": 1})},

    // Attachments
    {Id: "att_meter", Name: "TNT_Attachment_AssetFlowMeter", Description: "Counts metered flow and forwards asset to its destination.", Model: TNT_Attachment_AssetFlowMeter(nil)},
    {Id: "att_tap_opener", Name: "TNT_Attachment_TapOpener", Description: "Queues a tap to open after current flow stops.", Model: TNT_Attachment_TapOpener(nil)},
    {Id: "att_connect_auth", Name: "TNT_Attachment_ConnectAuthority", Description: "Authority to reconnect an attachment's destination.", Model: TNT_Attachment_ConnectAuthority(nil)},

    // Connections demo (account/tank/attachment) + restricted-asset triple-check gates
    {Id: "connections_demo", Name: "TNT_Connections_Demo", Description: "Account/Tank/Attachment connections with path authorization & restricted-asset checks.", Model: TNT_Connections_Demo(nil)},
}

// ======================================================================
//                              CORE TANK
// ======================================================================

func TNT_CoreTank(_ map[string]any) *mm.Model {
    // Objects: asset in tank, core deposit, account for sinks, tank authority
    obj := mm.New([]string{Asset, Core, Account, TankObj, Auth})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            // Balances / state
            "tank_balance":   {X: 360, Y: 200},  // $asset
            "account_funds":  {X: 120, Y: 200},  // $asset (source)
            "tank_exists":    {X: 360, Y: 260, Initial: mm.T(1)}, // tank is alive
            "emergency_key":  {X: 360, Y: 80},   // $tank authority tokens

            // Deposit lifecycle (core asset)
            "deposit_locked": {X: 320, Y: 320},  // $core held with tank lifetime
            "deposit_refund": {X: 560, Y: 320},  // $core returned to fee_payer

            // Destinations (connections)
            "dest_account":   {X: 600, Y: 200},  // $asset -> account
            "dest_new_tank":  {X: 600, Y: 300},  // $asset -> new tank balance

            // Path authorization guard for remote deposits
            "auth_src_ok":    {X: 200, Y: 140},  // $auth (authorized remote source)
        },
        Transitions: map[string]mm.Transition{
            "deposit":          {X: 240, Y: 200},
            "emergency_drain":  {X: 480, Y: 140}, // destructor tap
            "create_tank":      {X: 260, Y: 320}, // locks core deposit
        },
        Arrows: []mm.Arrow{
            // Create tank: pay core deposit (locks until destructor)
            obj.Arrow(mm.Arc{Source: "deposit_refund", Target: "create_tank", Object: Core, Weight: 0}),
            obj.Arrow(mm.Arc{Source: "create_tank",    Target: "deposit_locked", Object: Core, Weight: 1}),

            // Remote path auth must be established to allow deposits from other tanks/accounts
            obj.Arrow(mm.Arc{Source: "auth_src_ok", Target: "deposit", Object: Auth}),
            obj.Arrow(mm.Arc{Source: "account_funds", Target: "deposit", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "deposit", Target: "tank_balance", Object: Asset}),

            // Emergency drain must consume authority and (optionally) destroy tank
            obj.Arrow(mm.Arc{Source: "emergency_key",  Target: "emergency_drain", Object: TankObj}),
            obj.Arrow(mm.Arc{Source: "tank_balance",   Target: "emergency_drain", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "tank_exists",    Target: "emergency_drain", Object: TankObj}), // destructor path

            // Route drained assets; choose destination in composition
            obj.Arrow(mm.Arc{Source: "emergency_drain", Target: "dest_account",  Object: Asset}),
            obj.Arrow(mm.Arc{Source: "emergency_drain", Target: "dest_new_tank", Object: Asset}),

            // Refund core deposit to fee payer on destructor
            obj.Arrow(mm.Arc{Source: "emergency_drain", Target: "deposit_refund", Object: Core}),
        },
    }
    m.Binding = func(string) string {
        return "# TNT Core Tank\n" +
            "- `create_tank` locks $core as deposit.\n" +
            "- `deposit` requires `$auth` from authorized connections for remote sources.\n" +
            "- `emergency_drain` consumes tank authority & existence (destructor), routes assets, refunds deposit.\n" +
            m.Markdown()
    }
    return m
}

// ======================================================================
//                          REQUIREMENTS (Taps)
// ======================================================================

// Documentation-only (+ per-opening limit via $quota)
func TNT_Tap_ImmediateLimit(opts map[string]any) *mm.Model {
    limit := getInt(opts, "limit", 1)
    obj := mm.New([]string{Asset, Account, Ctrl, Quota})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            "tank_balance": {X: 360, Y: 200},
            "doc_ready":    {X: 240, Y: 100},                                   // $ctrl
            "quota_opening":{X: 240, Y: 300, Initial: mm.T(limit), Capacity: mm.T(limit)}, // $quota units
            "dest_account": {X: 600, Y: 200},
        },
        Transitions: map[string]mm.Transition{
            "provide_doc": {X: 180, Y: 100},
            "tap_release": {X: 480, Y: 200},
        },
        Arrows: []mm.Arrow{
            obj.Arrow(mm.Arc{Source: "provide_doc", Target: "doc_ready", Object: Ctrl}),
            obj.Arrow(mm.Arc{Source: "doc_ready", Target: "tap_release", Object: Ctrl}),
            obj.Arrow(mm.Arc{Source: "quota_opening", Target: "tap_release", Object: Quota}),
            obj.Arrow(mm.Arc{Source: "tank_balance", Target: "tap_release", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "tap_release", Target: "dest_account", Object: Asset}),
        },
    }
    m.Binding = func(string) string {
        return "# Immediate Flow Limit + Documentation\n" + m.Markdown()
    }
    return m
}

// Cumulative total limit (consumes from a finite $quota pool)
func TNT_Tap_CumulativeLimit(opts map[string]any) *mm.Model {
    total := getInt(opts, "limitTotal", 100)
    obj := mm.New([]string{Asset, Quota})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            "tank_balance": {X: 360, Y: 200},
            "quota_total":  {X: 260, Y: 290, Initial: mm.T(total), Capacity: mm.T(total)}, // $quota of units
            "released":     {X: 460, Y: 290},                                               // accounting
            "dest_account": {X: 600, Y: 200},
        },
        Transitions: map[string]mm.Transition{
            "tap_release": {X: 480, Y: 200},
        },
        Arrows: []mm.Arrow{
            obj.Arrow(mm.Arc{Source: "quota_total",  Target: "tap_release", Object: Quota}),
            obj.Arrow(mm.Arc{Source: "tank_balance", Target: "tap_release", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "tap_release",  Target: "dest_account", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "tap_release",  Target: "released", Object: Quota}),
        },
    }
    m.Binding = func(string) string { return "# Cumulative Flow Limit\n" + m.Markdown() }
    return m
}

// Periodic flow limit: per period quota refilled by clock ticks ($time)
func TNT_Tap_PeriodicLimit(opts map[string]any) *mm.Model {
    per := getInt(opts, "periodLimit", 50)
    obj := mm.New([]string{Asset, Quota, Time})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            "tank_balance":  {X: 360, Y: 200},
            "period_quota":  {X: 260, Y: 300, Initial: mm.T(per), Capacity: mm.T(per)},
            "period_tick":   {X: 160, Y: 100}, // $time signal
            "dest_account":  {X: 600, Y: 200},
        },
        Transitions: map[string]mm.Transition{
            "clock_tick":  {X: 220, Y: 100},
            "tap_release": {X: 480, Y: 200},
        },
        Arrows: []mm.Arrow{
            // On each tick, refill quota back toward 'per' (here reset to full)
            obj.Arrow(mm.Arc{Source: "period_tick", Target: "clock_tick", Object: Time}),
            obj.Arrow(mm.Arc{Source: "clock_tick",  Target: "period_quota", Object: Quota, Weight: 0}), // set to per for immediate full reset if your engine supports; else model refill pool.

            obj.Arrow(mm.Arc{Source: "period_quota", Target: "tap_release", Object: Quota}),
            obj.Arrow(mm.Arc{Source: "tank_balance", Target: "tap_release", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "tap_release",  Target: "dest_account", Object: Asset}),
        },
    }
    m.Binding = func(string) string { return "# Periodic Flow Limit (clock-driven reset)\n" + m.Markdown() }
    return m
}

// Time lock windows: require 'unlocked' token sourced by time events
func TNT_Tap_TimeLock(_ map[string]any) *mm.Model {
    obj := mm.New([]string{Asset, Time, Ctrl})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            "tank_balance": {X: 360, Y: 200},
            "unlocked":     {X: 260, Y: 120}, // $ctrl token present only during open window
            "time_signal":  {X: 140, Y: 120}, // $time token from scheduler
            "dest_account": {X: 600, Y: 200},
        },
        Transitions: map[string]mm.Transition{
            "set_window":  {X: 200, Y: 120},
            "tap_release": {X: 480, Y: 200},
        },
        Arrows: []mm.Arrow{
            obj.Arrow(mm.Arc{Source: "time_signal", Target: "set_window", Object: Time}),
            obj.Arrow(mm.Arc{Source: "set_window",  Target: "unlocked",   Object: Ctrl}),

            obj.Arrow(mm.Arc{Source: "unlocked",    Target: "tap_release", Object: Ctrl}),
            obj.Arrow(mm.Arc{Source: "tank_balance",Target: "tap_release", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "tap_release", Target: "dest_account",Object: Asset}),
        },
    }
    m.Binding = func(string) string { return "# Time Lock (windowed)\n" + m.Markdown() }
    return m
}

// Minimum tank level (reserve floor): tap draws from spendable; reserve never consumed
func TNT_Tap_MinimumTankLevel(opts map[string]any) *mm.Model {
    reserve := getInt(opts, "reserve", 20)
    obj := mm.New([]string{Asset})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            "tank_balance":  {X: 320, Y: 180},                 // total balance
            "spendable":     {X: 420, Y: 180},                 // movable part
            "reserve":       {X: 320, Y: 260, Initial: mm.T(reserve), Capacity: mm.T(reserve)}, // reserved floor
            "dest_account":  {X: 640, Y: 180},
        },
        Transitions: map[string]mm.Transition{
            "make_spendable": {X: 370, Y: 180},
            "tap_release":    {X: 540, Y: 180},
        },
        Arrows: []mm.Arrow{
            // Move only the balance above reserve into 'spendable' (approximate)
            obj.Arrow(mm.Arc{Source: "tank_balance", Target: "make_spendable", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "make_spendable", Target: "spendable", Object: Asset}),
            // Tap consumes only from 'spendable'
            obj.Arrow(mm.Arc{Source: "spendable", Target: "tap_release", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "tap_release", Target: "dest_account", Object: Asset}),
        },
    }
    m.Binding = func(string) string {
        return "# Minimum Tank Level (reserve floor)\n" +
            "Reserve tokens modeled in 'reserve'; spendable is separated before tap.\n" + m.Markdown()
    }
    return m
}

// Reviewer approval workflow (stateful)
func TNT_Tap_ReviewRequirement(_ map[string]any) *mm.Model {
    obj := mm.New([]string{Asset, Ctrl})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            "tank_balance":    {X: 360, Y: 200},
            "review_queue":    {X: 180, Y: 140},
            "review_approved": {X: 240, Y: 100, Capacity: mm.T(1)},
            "dest_account":    {X: 600, Y: 200},
        },
        Transitions: map[string]mm.Transition{
            "submit_request": {X: 120, Y: 140},
            "approve":        {X: 210, Y: 100},
            "tap_release":    {X: 480, Y: 200},
        },
        Arrows: []mm.Arrow{
            obj.Arrow(mm.Arc{Source: "submit_request", Target: "review_queue",    Object: Ctrl}),
            obj.Arrow(mm.Arc{Source: "review_queue",   Target: "approve",         Object: Ctrl}),
            obj.Arrow(mm.Arc{Source: "approve",        Target: "review_approved", Object: Ctrl}),

            obj.Arrow(mm.Arc{Source: "review_approved", Target: "tap_release", Object: Ctrl}),
            obj.Arrow(mm.Arc{Source: "tank_balance",    Target: "tap_release", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "tap_release",     Target: "dest_account", Object: Asset}),
        },
    }
    m.Binding = func(string) string { return "# Review Requirement\n" + m.Markdown() }
    return m
}

// Documentation-only requirement (no review)
func TNT_Tap_Documentation(_ map[string]any) *mm.Model {
    obj := mm.New([]string{Asset, Ctrl})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            "tank_balance": {X: 360, Y: 200},
            "doc_ready":    {X: 240, Y: 100},
            "dest_account": {X: 600, Y: 200},
        },
        Transitions: map[string]mm.Transition{
            "provide_doc": {X: 180, Y: 100},
            "tap_release": {X: 480, Y: 200},
        },
        Arrows: []mm.Arrow{
            obj.Arrow(mm.Arc{Source: "provide_doc", Target: "doc_ready", Object: Ctrl}),
            obj.Arrow(mm.Arc{Source: "doc_ready", Target: "tap_release", Object: Ctrl}),
            obj.Arrow(mm.Arc{Source: "tank_balance", Target: "tap_release", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "tap_release", Target: "dest_account", Object: Asset}),
        },
    }
    m.Binding = func(string) string { return "# Documentation Requirement\n" + m.Markdown() }
    return m
}

// Delay with optional veto & maturity
func TNT_Tap_DelayRequirement(_ map[string]any) *mm.Model {
    obj := mm.New([]string{Asset, Ctrl, Time})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            "tank_balance": {X: 360, Y: 200},
            "delay_req":    {X: 180, Y: 140},
            "delay_mature": {X: 240, Y: 100},
            "veto_power":   {X: 200, Y: 60, Capacity: mm.T(1)}, // optional presence
            "time_elapses": {X: 140, Y: 100}, // $time
            "dest_account": {X: 600, Y: 200},
        },
        Transitions: map[string]mm.Transition{
            "request":    {X: 120, Y: 140},
            "tick":       {X: 200, Y: 120},
            "veto":       {X: 200, Y: 80},
            "tap_release":{X: 480, Y: 200},
        },
        Arrows: []mm.Arrow{
            obj.Arrow(mm.Arc{Source: "request",     Target: "delay_req",    Object: Ctrl}),
            obj.Arrow(mm.Arc{Source: "time_elapses",Target: "tick",         Object: Time}),
            obj.Arrow(mm.Arc{Source: "tick",        Target: "delay_mature", Object: Ctrl}),
            // Veto consumes the maturity token if used
            obj.Arrow(mm.Arc{Source: "veto_power",  Target: "veto",         Object: Ctrl}),
            obj.Arrow(mm.Arc{Source: "delay_mature",Target: "veto",         Object: Ctrl}),

            obj.Arrow(mm.Arc{Source: "delay_mature",Target: "tap_release",  Object: Ctrl}),
            obj.Arrow(mm.Arc{Source: "tank_balance",Target: "tap_release",  Object: Asset}),
            obj.Arrow(mm.Arc{Source: "tap_release", Target: "dest_account", Object: Asset}),
        },
    }
    m.Binding = func(string) string { return "# Delay Requirement (with optional veto)\n" + m.Markdown() }
    return m
}

// Hash preimage requirement
func TNT_Tap_HashPreimage(_ map[string]any) *mm.Model {
    obj := mm.New([]string{Asset, Hash})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            "tank_balance": {X: 360, Y: 200},
            "preimage_ok":  {X: 240, Y: 120}, // $hash token created by verifier
            "dest_account": {X: 600, Y: 200},
        },
        Transitions: map[string]mm.Transition{
            "verify_preimage": {X: 180, Y: 120},
            "tap_release":     {X: 480, Y: 200},
        },
        Arrows: []mm.Arrow{
            obj.Arrow(mm.Arc{Source: "verify_preimage", Target: "preimage_ok", Object: Hash}),
            obj.Arrow(mm.Arc{Source: "preimage_ok", Target: "tap_release", Object: Hash}),
            obj.Arrow(mm.Arc{Source: "tank_balance", Target: "tap_release", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "tap_release", Target: "dest_account", Object: Asset}),
        },
    }
    m.Binding = func(string) string { return "# Hash Preimage Requirement\n" + m.Markdown() }
    return m
}

// Ticket requirement (signed & sequenced)
func TNT_Tap_TicketRequirement(_ map[string]any) *mm.Model {
    obj := mm.New([]string{Asset, Ticket, Ctrl})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            "tank_balance":  {X: 360, Y: 200},
            "ticket_pool":   {X: 180, Y: 140},    // available signed tickets
            "next_ticket":   {X: 220, Y: 100, Initial: mm.T(1)}, // sequence cursor (proxy)
            "ticket_ok":     {X: 260, Y: 100},
            "tickets_used":  {X: 300, Y: 260},    // accounting
            "dest_account":  {X: 600, Y: 200},
        },
        Transitions: map[string]mm.Transition{
            "redeem_ticket": {X: 240, Y: 120},
            "tap_release":   {X: 480, Y: 200},
        },
        Arrows: []mm.Arrow{
            // Redeem: consume a ticket & sequence cursor → produce 'ticket_ok' and advance cursor
            obj.Arrow(mm.Arc{Source: "ticket_pool", Target: "redeem_ticket", Object: Ticket}),
            obj.Arrow(mm.Arc{Source: "next_ticket", Target: "redeem_ticket", Object: Ctrl}),
            obj.Arrow(mm.Arc{Source: "redeem_ticket", Target: "ticket_ok", Object: Ticket}),
            obj.Arrow(mm.Arc{Source: "redeem_ticket", Target: "tickets_used", Object: Ctrl}),

            // Tap needs ticket_ok + asset
            obj.Arrow(mm.Arc{Source: "ticket_ok",    Target: "tap_release", Object: Ticket}),
            obj.Arrow(mm.Arc{Source: "tank_balance", Target: "tap_release", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "tap_release",  Target: "dest_account", Object: Asset}),
        },
    }
    m.Binding = func(string) string { return "# Ticket Requirement (sequenced)\n" + m.Markdown() }
    return m
}

// Exchange requirement driven by asset_flow_meter ticks
func TNT_Tap_ExchangeRequirement(opts map[string]any) *mm.Model {
    releasePerTick := getInt(opts, "releasePerTick", 1)
    tickAmount := getInt(opts, "tickAmount", 1)
    _ = tickAmount // documented formula; here 1 tick ⇒ releasePerTick units

    obj := mm.New([]string{Asset, Meter})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            "tank_balance":  {X: 360, Y: 200},
            "meter_ticks":   {X: 240, Y: 140}, // produced by attachment
            "amount_released":{X: 460, Y: 280}, // accounting
            "dest_account":  {X: 600, Y: 200},
        },
        Transitions: map[string]mm.Transition{
            "tap_release": {X: 480, Y: 200},
        },
        Arrows: []mm.Arrow{
            obj.Arrow(mm.Arc{Source: "meter_ticks",  Target: "tap_release", Object: Meter}),
            obj.Arrow(mm.Arc{Source: "tank_balance", Target: "tap_release", Object: Asset, Weight: int64(releasePerTick)}),
            obj.Arrow(mm.Arc{Source: "tap_release",  Target: "dest_account", Object: Asset, Weight: int64(releasePerTick)}),
            obj.Arrow(mm.Arc{Source: "tap_release",  Target: "amount_released", Object: Asset, Weight: int64(releasePerTick)}),
        },
    }
    m.Binding = func(string) string {
        return "# Exchange Requirement (meter-driven)\n" +
            "1 $meter tick authorizes releasePerTick units of $asset.\n" + m.Markdown()
    }
    return m
}

// ======================================================================
//                          ATTACHMENTS
// ======================================================================

// Asset Flow Meter: receives $asset, counts into $meter ticks, forwards asset
func TNT_Attachment_AssetFlowMeter(_ map[string]any) *mm.Model {
    obj := mm.New([]string{Asset, Meter})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            "meter_inbox":  {X: 200, Y: 160},   // $asset ingress
            "meter_ticks":  {X: 260, Y: 120},   // $meter tick counter
            "metered_out":  {X: 440, Y: 160},   // $asset forwarded to destination connection
        },
        Transitions: map[string]mm.Transition{
            "meter_ingest": {X: 240, Y: 160},
            "emit_tick":    {X: 260, Y: 140},
            "forward":      {X: 360, Y: 160},
        },
        Arrows: []mm.Arrow{
            obj.Arrow(mm.Arc{Source: "meter_inbox", Target: "meter_ingest", Object: Asset}),
            // Each unit through emits a tick (proxy 1:1)
            obj.Arrow(mm.Arc{Source: "meter_ingest", Target: "emit_tick", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "emit_tick", Target: "meter_ticks", Object: Meter}),
            // Forward the underlying asset to the preconfigured destination
            obj.Arrow(mm.Arc{Source: "meter_ingest", Target: "forward", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "forward", Target: "metered_out", Object: Asset}),
        },
    }
    m.Binding = func(string) string { return "# Attachment: Asset Flow Meter\n" + m.Markdown() }
    return m
}

// Tap Opener: when it receives $asset, it produces an $ctrl 'open_ok' to queue a tap
func TNT_Attachment_TapOpener(_ map[string]any) *mm.Model {
    obj := mm.New([]string{Asset, Ctrl})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            "opener_inbox": {X: 220, Y: 160}, // $asset ingress
            "open_ok":      {X: 320, Y: 120}, // $ctrl token to enable target tap
        },
        Transitions: map[string]mm.Transition{
            "queue_open": {X: 260, Y: 140},
        },
        Arrows: []mm.Arrow{
            obj.Arrow(mm.Arc{Source: "opener_inbox", Target: "queue_open", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "queue_open",   Target: "open_ok",    Object: Ctrl}),
        },
    }
    m.Binding = func(string) string { return "# Attachment: Tap Opener\n" + m.Markdown() }
    return m
}

// Attachment Connect Authority: produces $ctrl 'connect_ok' when authority is present
func TNT_Attachment_ConnectAuthority(_ map[string]any) *mm.Model {
    obj := mm.New([]string{Ctrl})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            "connect_authority": {X: 220, Y: 160, Capacity: mm.T(1)}, // authority token present?
            "connect_ok":        {X: 320, Y: 140}, // signal that reconnection is permitted
        },
        Transitions: map[string]mm.Transition{
            "authorize_connect": {X: 260, Y: 150},
        },
        Arrows: []mm.Arrow{
            obj.Arrow(mm.Arc{Source: "connect_authority", Target: "authorize_connect", Object: Ctrl}),
            obj.Arrow(mm.Arc{Source: "authorize_connect", Target: "connect_ok", Object: Ctrl}),
        },
    }
    m.Binding = func(string) string { return "# Attachment: Connect Authority\n" + m.Markdown() }
    return m
}

// ======================================================================
//                       CONNECTIONS & RESTRICTIONS
// ======================================================================

// Demonstrates three connection types and path/restricted-asset checks.
// - account_fund_connection → deposit path auth gate (auth_src_ok)
// - connection_fund_account → emits to account dest (with recipient auth)
// - tank-to-attachment path included
func TNT_Connections_Demo(_ map[string]any) *mm.Model {
    obj := mm.New([]string{Asset, Account, Auth})
    m := &mm.Model{
        Objects: obj.Objects,
        Places: map[string]mm.Place{
            // Account → Tank (account_fund_connection)
            "acct_src":     {X: 120, Y: 140}, // account balance
            "auth_src_ok":  {X: 180, Y: 100}, // authorized source for deposit
            "tank_balance": {X: 360, Y: 140},

            // Tank → Account (connection_fund_account)
            "recipient_auth": {X: 560, Y: 100}, // recipient is whitelisted for asset
            "acct_dest":      {X: 640, Y: 140}, // account balance

            // Tank → Attachment
            "att_inbox":    {X: 360, Y: 220}, // attachment that can receive
        },
        Transitions: map[string]mm.Transition{
            "account_fund_connection":   {X: 240, Y: 140},
            "connection_fund_account":   {X: 560, Y: 140},
            "connection_to_attachment":  {X: 360, Y: 200},
        },
        Arrows: []mm.Arrow{
            // Account -> Tank requires auth gate (deposit path restriction)
            obj.Arrow(mm.Arc{Source: "auth_src_ok", Target: "account_fund_connection", Object: Auth}),
            obj.Arrow(mm.Arc{Source: "acct_src", Target: "account_fund_connection", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "account_fund_connection", Target: "tank_balance", Object: Asset}),

            // Tank -> Account requires recipient restricted-asset authorization
            obj.Arrow(mm.Arc{Source: "recipient_auth", Target: "connection_fund_account", Object: Auth}),
            obj.Arrow(mm.Arc{Source: "tank_balance",   Target: "connection_fund_account", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "connection_fund_account", Target: "acct_dest", Object: Asset}),

            // Tank -> Attachment path (attachment must allow deposits)
            obj.Arrow(mm.Arc{Source: "tank_balance", Target: "connection_to_attachment", Object: Asset}),
            obj.Arrow(mm.Arc{Source: "connection_to_attachment", Target: "att_inbox", Object: Asset}),
        },
    }
    m.Binding = func(string) string {
        return "# Connections & Restrictions Demo\n" +
            "- Account→Tank deposits require `$auth` (authorized source).\n" +
            "- Tank→Account deposits require recipient `$auth` (restricted assets check).\n" +
            "- Tank→Attachment shows attachment deposit path.\n" + m.Markdown()
    }
    return m
}


var (
	tntRegistryMap = make(map[string]*Record)
)

func init() {
	for _, rec := range tntRegistry {
		tntRegistryMap[rec.Id] = rec
		rec.Model.Binding = func(_ string) string {
			var sb strings.Builder
			sb.WriteString("# " + rec.Name + "\n")
			sb.WriteString(rec.Description + "\n\n")
			sb.WriteString("## Model\n")
			sb.WriteString(rec.Model.Markdown() + "\n")
			return sb.String()
		}
	}
}

func indexPage(_ string) string {
	content := `# BSIP072 Metamodel
This is a collection of BSIP072 metamodels that demonstrate various tank and tap functionalities.

Each model is designed to illustrate specific aspects of asset flow management and can be used as a foundation for building more complex systems.

## Models
`
	for _, rec := range tntRegistryMap {
		content += "- [" + rec.Name + "](" + basePath + ":" + rec.Id + "): " + rec.Description + "\n"
	}
	content += `## How can this be used?
- Extend with additional asset flow constraints.
- Use as a foundation for dApps that need asset flow management.
- Simulate and analyze asset flows off-chain for insight.
`
	return content
}

func Render(path string) string {
	if rec, ok := tntRegistryMap[path]; ok {
		if content, ok := rec.Model.Binding.(func(string) string); ok {
			return content(path)
		}
		return rec.Model.Markdown()
	}
	return indexPage(path)
}
