import Foundation

// MARK: - Advanced iTIP Workflow Support

/// Advanced iTIP (Internet Calendaring and Scheduling) workflow implementation
/// Supports complex scheduling scenarios and delegation workflows
public struct ICalAdvancediTIP: Sendable {

    /// iTIP methods for advanced workflows
    public enum AdvancedMethod: String, CaseIterable, Sendable {
        case publish = "PUBLISH"
        case request = "REQUEST"
        case reply = "REPLY"
        case add = "ADD"
        case cancel = "CANCEL"
        case refresh = "REFRESH"
        case counter = "COUNTER"
        case declineCounter = "DECLINECOUNTER"
        case pollstatus = "POLLSTATUS"

        // Advanced delegation methods
        case delegate = "DELEGATE"
        case undoDelegate = "UNDO-DELEGATE"
        case forward = "FORWARD"

        // Resource booking methods
        case resourceRequest = "RESOURCE-REQUEST"
        case resourceReply = "RESOURCE-REPLY"
        case resourceCancel = "RESOURCE-CANCEL"
    }

    /// Delegation workflow states
    public enum DelegationState: String, Sendable {
        case delegated = "DELEGATED"
        case delegatedFrom = "DELEGATED-FROM"
        case delegatedTo = "DELEGATED-TO"
        case pending = "PENDING"
        case completed = "COMPLETED"
        case failed = "FAILED"
    }

    /// Resource booking states
    public enum ResourceBookingState: String, Sendable {
        case requested = "REQUESTED"
        case tentative = "TENTATIVE"
        case confirmed = "CONFIRMED"
        case denied = "DENIED"
        case cancelled = "CANCELLED"
        case waitlisted = "WAITLISTED"
    }

    /// Complex scheduling workflow
    public struct SchedulingWorkflow: Sendable {
        public let id: String
        public let method: AdvancedMethod
        public let sequence: Int
        public let organizer: String
        public let attendees: [ICalAttendee]
        public var delegations: [Delegation]
        public var resourceBookings: [ResourceBooking]
        public var counterProposals: [CounterProposal]
        public var pollStatus: PollStatus?

        public init(
            id: String = UUID().uuidString,
            method: AdvancedMethod,
            sequence: Int = 0,
            organizer: String,
            attendees: [ICalAttendee] = []
        ) {
            self.id = id
            self.method = method
            self.sequence = sequence
            self.organizer = organizer
            self.attendees = attendees
            self.delegations = []
            self.resourceBookings = []
            self.counterProposals = []
        }
    }

    /// Delegation information
    public struct Delegation: Sendable {
        public let id: String
        public let delegatedFrom: ICalAttendee
        public let delegatedTo: ICalAttendee
        public let state: DelegationState
        public let timestamp: Date
        public let reason: String?
        public let permissions: DelegationPermissions

        public init(
            id: String = UUID().uuidString,
            delegatedFrom: ICalAttendee,
            delegatedTo: ICalAttendee,
            state: DelegationState = .pending,
            reason: String? = nil,
            permissions: DelegationPermissions = .full
        ) {
            self.id = id
            self.delegatedFrom = delegatedFrom
            self.delegatedTo = delegatedTo
            self.state = state
            self.timestamp = Date()
            self.reason = reason
            self.permissions = permissions
        }
    }

    /// Delegation permissions
    public struct DelegationPermissions: OptionSet, Sendable {
        public let rawValue: Int

        public static let viewOnly = DelegationPermissions(rawValue: 1 << 0)
        public static let respond = DelegationPermissions(rawValue: 1 << 1)
        public static let modify = DelegationPermissions(rawValue: 1 << 2)
        public static let delegate = DelegationPermissions(rawValue: 1 << 3)
        public static let cancel = DelegationPermissions(rawValue: 1 << 4)

        public static let full: DelegationPermissions = [.viewOnly, .respond, .modify, .delegate, .cancel]
        public static let readonly: DelegationPermissions = [.viewOnly]
        public static let respondOnly: DelegationPermissions = [.viewOnly, .respond]

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    /// Resource booking information
    public struct ResourceBooking: Sendable {
        public let id: String
        public let resource: ICalResourceComponent
        public let state: ResourceBookingState
        public let requestedBy: ICalAttendee
        public let timestamp: Date
        public let priority: Int?
        public let conflictResolution: ConflictResolution?

        public init(
            id: String = UUID().uuidString,
            resource: ICalResourceComponent,
            state: ResourceBookingState = .requested,
            requestedBy: ICalAttendee,
            priority: Int? = nil,
            conflictResolution: ConflictResolution? = nil
        ) {
            self.id = id
            self.resource = resource
            self.state = state
            self.requestedBy = requestedBy
            self.timestamp = Date()
            self.priority = priority
            self.conflictResolution = conflictResolution
        }
    }

    /// Conflict resolution strategies
    public enum ConflictResolution: String, Sendable {
        case overwrite = "OVERWRITE"
        case merge = "MERGE"
        case reject = "REJECT"
        case queue = "QUEUE"
        case delegate = "DELEGATE"
    }

    /// Counter proposal information
    public struct CounterProposal: Sendable {
        public let id: String
        public let proposedBy: ICalAttendee
        public let originalEvent: ICalEvent
        public let proposedChanges: [PropertyChange]
        public let timestamp: Date
        public let reason: String?
        public let status: CounterProposalStatus

        public init(
            id: String = UUID().uuidString,
            proposedBy: ICalAttendee,
            originalEvent: ICalEvent,
            proposedChanges: [PropertyChange],
            reason: String? = nil,
            status: CounterProposalStatus = .pending
        ) {
            self.id = id
            self.proposedBy = proposedBy
            self.originalEvent = originalEvent
            self.proposedChanges = proposedChanges
            self.timestamp = Date()
            self.reason = reason
            self.status = status
        }
    }

    /// Counter proposal status
    public enum CounterProposalStatus: String, Sendable {
        case pending = "PENDING"
        case accepted = "ACCEPTED"
        case rejected = "REJECTED"
        case superseded = "SUPERSEDED"
    }

    /// Property change for counter proposals
    public struct PropertyChange: Sendable {
        public let property: String
        public let originalValue: String?
        public let proposedValue: String?
        public let changeType: ChangeType

        public enum ChangeType: String, Sendable {
            case add = "ADD"
            case modify = "MODIFY"
            case remove = "REMOVE"
        }

        public init(property: String, originalValue: String?, proposedValue: String?, changeType: ChangeType) {
            self.property = property
            self.originalValue = originalValue
            self.proposedValue = proposedValue
            self.changeType = changeType
        }
    }

    /// Poll status for group scheduling
    public struct PollStatus: Sendable {
        public let pollId: String
        public let question: String
        public let options: [PollOption]
        public let responses: [PollResponse]
        public let deadline: Date?
        public let isActive: Bool

        public init(
            pollId: String = UUID().uuidString,
            question: String,
            options: [PollOption],
            deadline: Date? = nil,
            isActive: Bool = true
        ) {
            self.pollId = pollId
            self.question = question
            self.options = options
            self.responses = []
            self.deadline = deadline
            self.isActive = isActive
        }
    }

    /// Poll option
    public struct PollOption: Sendable, Identifiable {
        public let id: String
        public let text: String
        public let value: String
        public let weight: Int?

        public init(id: String = UUID().uuidString, text: String, value: String, weight: Int? = nil) {
            self.id = id
            self.text = text
            self.value = value
            self.weight = weight
        }
    }

    /// Poll response
    public struct PollResponse: Sendable {
        public let respondent: ICalAttendee
        public let selectedOptions: [String]
        public let timestamp: Date
        public let comment: String?

        public init(respondent: ICalAttendee, selectedOptions: [String], comment: String? = nil) {
            self.respondent = respondent
            self.selectedOptions = selectedOptions
            self.timestamp = Date()
            self.comment = comment
        }
    }
}

// MARK: - Advanced iTIP Workflow Manager

/// Manages complex iTIP workflows and scheduling operations
public struct ICalAdvancediTIPManager: Sendable {

    public init() {
    }

    /// Create a delegation workflow
    public static func createDelegation(
        from delegator: String,
        to delegate: String,
        permissions: ICalAdvancediTIP.DelegationPermissions = .full,
        reason: String? = nil
    ) -> ICalAdvancediTIP.Delegation {
        // Create simplified attendee representations
        let delegatorAttendee = ICalAttendee(email: delegator)
        let delegateAttendee = ICalAttendee(email: delegate)

        return ICalAdvancediTIP.Delegation(
            delegatedFrom: delegatorAttendee,
            delegatedTo: delegateAttendee,
            reason: reason,
            permissions: permissions
        )
    }

    /// Process a counter proposal
    public static func processCounterProposal(
        _ proposal: ICalAdvancediTIP.CounterProposal,
        decision: ICalAdvancediTIP.CounterProposalStatus
    ) -> ICalEvent {
        var modifiedEvent = proposal.originalEvent

        if decision == .accepted {
            // Apply proposed changes
            for change in proposal.proposedChanges {
                switch change.changeType {
                case .add, .modify:
                    if let newValue = change.proposedValue {
                        modifiedEvent.setPropertyValue(change.property, value: newValue)
                    }
                case .remove:
                    modifiedEvent.setPropertyValue(change.property, value: nil)
                }
            }

            // Increment sequence number
            modifiedEvent.sequence = (modifiedEvent.sequence ?? 0) + 1
        }

        return modifiedEvent
    }

    /// Create a resource booking request
    public static func createResourceBooking(
        resource: ICalResourceComponent,
        requestedBy: String,
        priority: Int? = nil
    ) -> ICalAdvancediTIP.ResourceBooking {
        let attendee = ICalAttendee(email: requestedBy)
        return ICalAdvancediTIP.ResourceBooking(
            resource: resource,
            requestedBy: attendee,
            priority: priority
        )
    }

    /// Process resource booking conflicts
    public static func resolveResourceConflict(
        booking: ICalAdvancediTIP.ResourceBooking,
        conflictingBookings: [ICalAdvancediTIP.ResourceBooking],
        resolution: ICalAdvancediTIP.ConflictResolution
    ) -> [ICalAdvancediTIP.ResourceBooking] {
        var resolvedBookings = conflictingBookings

        switch resolution {
        case .overwrite:
            // Replace all conflicting bookings with the new one
            resolvedBookings = [booking]

        case .merge:
            // Try to find alternative time slots
            resolvedBookings.append(booking)

        case .reject:
            // Keep existing bookings, reject new one
            break

        case .queue:
            // Add to waiting list
            let queuedBooking = booking
            if case .requested = queuedBooking.state {
                resolvedBookings.append(
                    ICalAdvancediTIP.ResourceBooking(
                        id: queuedBooking.id,
                        resource: queuedBooking.resource,
                        state: .waitlisted,
                        requestedBy: queuedBooking.requestedBy,
                        priority: queuedBooking.priority
                    )
                )
            }

        case .delegate:
            // Try to find alternative resource
            resolvedBookings.append(booking)
        }

        return resolvedBookings
    }

    /// Create a poll for group decision making
    public static func createPoll(
        question: String,
        options: [ICalAdvancediTIP.PollOption],
        deadline: Date? = nil
    ) -> ICalAdvancediTIP.PollStatus {
        ICalAdvancediTIP.PollStatus(
            question: question,
            options: options,
            deadline: deadline
        )
    }

    /// Generate iTIP message for complex workflow
    public static func generateiTIPMessage(
        for workflow: ICalAdvancediTIP.SchedulingWorkflow,
        event: ICalEvent
    ) -> String {
        var lines: [String] = []

        // Calendar header
        lines.append("BEGIN:VCALENDAR")
        lines.append("VERSION:2.0")
        lines.append("PRODID:-//ICalendarKit//Advanced iTIP//EN")
        lines.append("METHOD:\(workflow.method.rawValue)")

        // Event with workflow metadata
        lines.append("BEGIN:VEVENT")
        lines.append("UID:\(event.uid)")
        lines.append("SEQUENCE:\(workflow.sequence)")

        if let dtstart = event.dateTimeStart {
            lines.append("DTSTART:\(ICalendarFormatter.format(dateTime: dtstart))")
        }

        if let dtend = event.dateTimeEnd {
            lines.append("DTEND:\(ICalendarFormatter.format(dateTime: dtend))")
        }

        if let summary = event.summary {
            lines.append("SUMMARY:\(summary)")
        }

        // Organizer
        lines.append("ORGANIZER:MAILTO:\(workflow.organizer)")

        // Attendees with delegation info
        for attendee in workflow.attendees {
            var attendeeLine = "ATTENDEE"

            if let cn = attendee.commonName {
                attendeeLine += ";CN=\"\(cn)\""
            }

            if let role = attendee.role {
                attendeeLine += ";ROLE=\(role.rawValue)"
            }

            if let partstat = attendee.participationStatus {
                attendeeLine += ";PARTSTAT=\(partstat.rawValue)"
            }

            // Add delegation info
            for delegation in workflow.delegations {
                if delegation.delegatedFrom.email == attendee.email {
                    attendeeLine += ";DELEGATED-TO=\"MAILTO:\(delegation.delegatedTo.email)\""
                }
                if delegation.delegatedTo.email == attendee.email {
                    attendeeLine += ";DELEGATED-FROM=\"MAILTO:\(delegation.delegatedFrom.email)\""
                }
            }

            attendeeLine += ":MAILTO:\(attendee.email)"
            lines.append(attendeeLine)
        }

        // Add workflow-specific properties
        for delegation in workflow.delegations {
            lines.append("X-DELEGATION-ID:\(delegation.id)")
            lines.append("X-DELEGATION-STATE:\(delegation.state.rawValue)")
            if let reason = delegation.reason {
                lines.append("X-DELEGATION-REASON:\(reason)")
            }
        }

        for booking in workflow.resourceBookings {
            lines.append("X-RESOURCE-BOOKING-ID:\(booking.id)")
            lines.append("X-RESOURCE-STATE:\(booking.state.rawValue)")
            if let priority = booking.priority {
                lines.append("X-RESOURCE-PRIORITY:\(priority)")
            }
        }

        for proposal in workflow.counterProposals {
            lines.append("X-COUNTER-PROPOSAL-ID:\(proposal.id)")
            lines.append("X-COUNTER-STATUS:\(proposal.status.rawValue)")
            if let reason = proposal.reason {
                lines.append("X-COUNTER-REASON:\(reason)")
            }
        }

        if let poll = workflow.pollStatus {
            lines.append("X-POLL-ID:\(poll.pollId)")
            lines.append("X-POLL-QUESTION:\(poll.question)")
            lines.append("X-POLL-ACTIVE:\(poll.isActive ? "TRUE" : "FALSE")")
        }

        lines.append("END:VEVENT")
        lines.append("END:VCALENDAR")

        return lines.joined(separator: "\r\n")
    }
}

// MARK: - Advanced iTIP Extensions

extension ICalEvent {
    /// Check if event has delegation workflows
    public var hasDelegations: Bool {
        attendees.contains { attendee in
            attendee.delegatedTo != nil || attendee.delegatedFrom != nil
        }
    }

    /// Get all delegated attendees
    public var delegatedAttendees: [ICalAttendee] {
        attendees.filter { $0.delegatedTo != nil }
    }

    /// Get all delegate attendees
    public var delegateAttendees: [ICalAttendee] {
        attendees.filter { $0.delegatedFrom != nil }
    }

    /// Add counter proposal metadata
    public mutating func addCounterProposalMetadata(_ proposal: ICalAdvancediTIP.CounterProposal) {
        setPropertyValue("X-COUNTER-PROPOSAL-ID", value: proposal.id)
        setPropertyValue("X-COUNTER-STATUS", value: proposal.status.rawValue)
        setPropertyValue("X-COUNTER-TIMESTAMP", value: ICalendarFormatter.format(dateTime: ICalDateTime(date: proposal.timestamp)))

        if let reason = proposal.reason {
            setPropertyValue("X-COUNTER-REASON", value: reason)
        }
    }
}

extension ICalAttendee {
    /// Create delegated attendee
    public static func delegated(
        email: String,
        commonName: String? = nil,
        delegatedTo: String,
        role: ICalRole = .requiredParticipant,
        participationStatus: ICalParticipationStatus = .delegated
    ) -> ICalAttendee {
        ICalAttendee(
            email: email,
            commonName: commonName,
            role: role,
            participationStatus: participationStatus,
            rsvp: false,
            delegatedTo: delegatedTo
        )
    }

    /// Create delegate attendee
    public static func delegate(
        email: String,
        commonName: String? = nil,
        delegatedFrom: String,
        role: ICalRole = .requiredParticipant,
        participationStatus: ICalParticipationStatus = .needsAction
    ) -> ICalAttendee {
        ICalAttendee(
            email: email,
            commonName: commonName,
            role: role,
            participationStatus: participationStatus,
            rsvp: true,
            delegatedFrom: delegatedFrom
        )
    }
}
