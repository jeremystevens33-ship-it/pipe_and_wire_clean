import 'package:flutter/material.dart';
import 'code_topic_screen.dart';
import 'working_clearances_code_screen.dart';

class DisconnectRequirementsCodeScreen extends StatelessWidget {
  const DisconnectRequirementsCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topic = CodeTopic(
      id: 'disconnect_requirements',
      title: 'What does “within sight” mean for a disconnect?',
      shortAnswer:
          'Visible from the equipment and no more than 50 ft away. Both conditions must be met. (Article 100)',
      corePoints: const [
        'A disconnect 20 ft away around a corner does not meet the within-sight requirement.',
        'A visible disconnect 60 ft away also does not meet it. A remote lockable disconnect is allowed only where the equipment’s rule permits it.',
      ],
      expandSections: const [
        CodeExpandSection(
          heading: 'Where does a motor disconnect have to be?',
          bullets: [
            'Provide a disconnect within sight of the motor and the driven machinery. The controller also needs its disconnect within sight of the controller, subject to the specific controller exceptions. (430.102(A), (B)(1))',
            'One disconnect can serve the controller and motor when it meets both location requirements, including visibility of the driven machinery. (430.102(B)(2))',
            'The separate motor disconnect can be omitted if the controller disconnect is lockable open and a local motor disconnect is impracticable or introduces additional hazards; or in an industrial installation with written safety procedures and maintenance/supervision ensuring only qualified persons service the equipment. (430.102(B), Exception)',
            'A lockable breaker alone does not establish that this motor exception applies. The disconnect must also have the required type and rating. (430.109, 430.110)',
          ],
        ),
        CodeExpandSection(
          heading: 'Where can I put an A/C or refrigeration disconnect?',
          bullets: [
            'Within sight of, and readily accessible from, the equipment. For other than cord-and-plug-connected equipment, provide the working space required by 110.26(A). (440.14)',
            'It may be on or within the equipment, but not on a panel designed for access to internal wiring and not where it covers the equipment nameplate.',
            'Readily accessible means reachable quickly without moving obstacles, climbing over or under them, or using a portable ladder. Keys are allowed; tools generally are not. (Article 100)',
            'If unqualified persons can readily access it, an enclosure door exposing energized parts must require a tool to open or be capable of being locked. This enclosure-access rule is separate from locking the disconnect OFF. (440.11)',
          ],
        ),
        CodeExpandSection(
          heading: 'Does a transformer need a disconnect beside it?',
          bullets: [
            'Transformers other than Class 2 or Class 3 require a disconnect. It can be within sight or remote. (450.14)',
            'A remote disconnect must be lockable in the open position under 110.25, and its location must be field-marked on the transformer.',
            'Example: a suitable upstream primary breaker can serve as the remote disconnect when it has the required installed locking provision and its location is marked on the transformer. A separate switch beside the transformer is not automatically required.',
          ],
        ),
        CodeExpandSection(
          heading: 'Can a breaker disconnect a hardwired appliance?',
          bullets: [
            'For a permanently connected nonmotor appliance over 300 VA, the branch-circuit switch or breaker can serve when it is within sight of the appliance or lockable open under 110.25. Example: a hardwired electric water heater. (422.31(B))',
            'For permanently connected motor-operated appliances over ⅛ hp, the disconnect must meet 430.109 and 430.110 and be within sight or lockable open. Do not apply the separate-motor exception to every appliance. (422.31(C))',
            'An accessible attachment plug and receptacle can serve for a cord-and-plug-connected appliance under 422.33(A). Unit-switch arrangements have their own conditions under 422.34.',
          ],
        ),
        CodeExpandSection(
          heading: 'Does every panel need its own main disconnect?',
          bullets: [
            'An ordinary feeder panel does not automatically need a main breaker in that panel. Its required overcurrent protection can be inside the panel or upstream, rated no higher than the panelboard. (408.36)',
            'Example: a 100A main-lug feeder panel protected by a suitable upstream 100A breaker can meet that protection rule.',
            'A separate building supplied by a feeder or branch circuit needs the building disconnect required by 225.31, located outside or inside nearest the conductor entry under 225.32, subject to its exceptions. This is a separate check from panel protection.',
            'For outside feeders supplying one- and two-family dwellings, 2023 NEC 225.41 requires a readily accessible outdoor emergency disconnect on or within sight of the dwelling. For a new residential service, see the question below.',
          ],
        ),
        CodeExpandSection(
          heading: 'New residential service: is a disconnect required?',
          bullets: [],
          content: _HouseServiceReference(),
        ),
        CodeExpandSection(
          heading: 'What qualifies as “lockable OFF”?',
          bullets: [
            'Where the NEC requires a lockable disconnect, it must accept a lock that holds it open. The locking provision must remain installed with or without the lock itself. (110.25)',
            'Use a suitable installed breaker locking attachment or switch locking provision. A loose lockout accessory carried in a tool bag does not meet the requirement to leave the provision installed.',
            'Mark the disconnect’s purpose unless its location and arrangement make it evident. Outside one- and two-family dwellings, identify the supply circuit’s source location too, unless it is evident. (110.22(A))',
          ],
        ),
      ],
      codeRefs: const [
        '2023 NEC Article 100: In Sight From / Readily Accessible',
        'NEC 110.22(A), 110.25, 110.26(A)',
        'NEC 430.102(A), (B), including Exceptions; 430.109 / 430.110',
        'NEC 440.11 / 440.14',
        'NEC 450.14',
        'NEC 422.31(B), (C) / 422.33(A) / 422.34',
        'NEC 408.36 / 225.31 / 225.32',
        'NEC 230.70(A)(1) / 230.85 / 230.82(3) / 225.41',
        'NEC 230.90 / 230.91',
      ],
      branchLinks: [
        CodeBranchLink(
          label:
              'Working Clearances: depth, width, height, and dedicated space',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const WorkingClearancesCodeScreen()),
          ),
        ),
      ],
    );

    return CodeTopicScreen(topic: topic);
  }
}

class _HouseServiceReference extends StatelessWidget {
  const _HouseServiceReference();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Utility pole / overhead service drop',
      'Weatherhead and service-entrance conductors',
      'Meter',
      'Outdoor service disconnect\nMain breaker in this example\nAlso serves as the emergency disconnect',
      'Distribution panel\nOutdoor or indoor',
      'Branch circuits',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'A common arrangement is meter first, then an outdoor main breaker. That one breaker can serve as both the service disconnect and the emergency disconnect. The diagram shows power flow; the meter, main breaker, and branch-circuit panel may share a listed combination enclosure.',
          style: TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < steps.length; i++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: i == 3 ? const Color(0xFF8B2525) : const Color(0xFF2C2C30),
              border: Border.all(color: const Color(0xFF909096)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(steps[i],
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          if (i < steps.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 3),
              child: Icon(Icons.arrow_downward, color: Colors.white, size: 22),
            ),
        ],
        const SizedBox(height: 12),
        ...const [
          'For a new one- or two-family dwelling service under the 2023 NEC, provide a readily accessible outdoor emergency disconnect on or within sight of the dwelling. An indoor main breaker alone does not satisfy this outdoor requirement. (230.85(A))',
          'In this example, turning the outdoor main breaker OFF disconnects the service-fed circuits downstream. That same device is marked EMERGENCY DISCONNECT, SERVICE DISCONNECT; those are two functions of one device. (230.85(B)(1), (E))',
          'A service disconnect can instead be a suitable lever-operated switch with the required service overcurrent protection. A main breaker combines switching and overcurrent protection; a fused service switch uses its handle to switch power and its fuses for overcurrent protection. (230.70, 230.90, 230.91)',
          'An outdoor panel with a suitable main breaker can provide both disconnect functions. If the distribution panel is separate, it can be indoors or outdoors and is supplied by a feeder from the service disconnect.',
          'The NEC does not require a separate switch ahead of the meter in this arrangement. Utility metering rules and the listed equipment determine the permitted meter/disconnect layout.',
          '230.85 also permits qualifying meter disconnects or other listed supply-side disconnects marked NOT SERVICE EQUIPMENT. Those arrangements still need a separate service disconnect; do not treat every outdoor emergency switch as the service disconnect. (230.85(B)(2), (3))',
        ].map((text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(text,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15, height: 1.3)),
            )),
      ],
    );
  }
}
