part of '../course_selection_page.dart';

class _SearchPanel extends StatefulWidget {
  const _SearchPanel({
    required this.controller,
    required this.useAdvancedFilterDialog,
  });

  static const _creditOptions = <int>[0, 1, 2, 3, 4, 6];

  final CourseSelectionController controller;
  final bool useAdvancedFilterDialog;

  @override
  State<_SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<_SearchPanel> {
  late final TextEditingController _keywordController;

  CourseSelectionController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController(text: controller.keyword);
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: SearchBar(
              controller: _keywordController,
              constraints: const BoxConstraints(minHeight: 56.0),
              hintText: '搜尋課程名稱',
              leading: const Icon(Icons.search),
              trailing: [
                IconButton(
                  tooltip: '搜尋',
                  onPressed: controller.isLoading ? null : _applyTextFilters,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
              enabled: !controller.isLoading,
              onSubmitted: (_) => _applyTextFilters(),
            ),
          ),
          if (controller.hasActiveFilter) ...[
            const SizedBox(height: 10.0),
            _ActiveFilterSummary(
              controller: controller,
              onClear: _clearFilters,
            ),
          ],
          const SizedBox(height: 10.0),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.isLoading
                  ? null
                  : () => _showAdvancedFilterSheet(context),
              icon: const Icon(Icons.tune),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('進階查詢'),
                  if (_advancedFilterCount > 0) ...[
                    const SizedBox(width: 8.0),
                    Badge(
                      label: Text(_advancedFilterCount.toString()),
                      backgroundColor: colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (controller.error != null && controller.courses.isNotEmpty) ...[
            const SizedBox(height: 10.0),
            Text('更新失敗，保留目前結果', style: TextStyle(color: colorScheme.error)),
          ],
        ],
      ),
    );
  }

  void _applyTextFilters() {
    unawaited(controller.search(keyword: _keywordController.text));
  }

  void _clearFilters() {
    _keywordController.clear();
    unawaited(controller.clearFilters());
  }

  int get _advancedFilterCount {
    return [
      controller.classNo.isNotEmpty,
      controller.serialNo.isNotEmpty,
      controller.departmentName.isNotEmpty,
      controller.collegeName.isNotEmpty,
      controller.instructor.isNotEmpty,
      controller.courseType != null,
      controller.credits.isNotEmpty,
      controller.hasVacancy != null,
      controller.classTimes.isNotEmpty,
    ].where((isActive) => isActive).length;
  }

  void _showAdvancedFilterSheet(BuildContext context) {
    if (widget.useAdvancedFilterDialog) {
      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) {
            return Dialog(
              clipBehavior: Clip.antiAlias,
              insetPadding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _CourseSelectionPageContentState
                      ._maxAdvancedFilterDialogWidth,
                ),
                child: SizedBox(
                  height: (MediaQuery.sizeOf(context).height - 64.0).clamp(
                    680.0,
                    760.0,
                  ),
                  child: _AdvancedFilterSheet(
                    controller: controller,
                    useDialogLayout: true,
                  ),
                ),
              ),
            );
          },
        ),
      );
      return;
    }

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) {
          return _AdvancedFilterSheet(controller: controller);
        },
      ),
    );
  }
}

class _AdvancedFilterSheet extends StatefulWidget {
  const _AdvancedFilterSheet({
    required this.controller,
    this.useDialogLayout = false,
  });

  final CourseSelectionController controller;
  final bool useDialogLayout;

  @override
  State<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<_AdvancedFilterSheet> {
  static const _classTimeWeekDays = ['一', '二', '三', '四', '五', '六', '日'];
  static const _classTimePeriods = [
    '1',
    '2',
    '3',
    '4',
    'Z',
    '5',
    '6',
    '7',
    '8',
    '9',
    'A',
    'B',
    'C',
    'D',
  ];

  late final TextEditingController _classNoController;
  late final TextEditingController _serialNoController;
  late final TextEditingController _departmentNameController;
  late final TextEditingController _collegeNameController;
  late final TextEditingController _instructorController;
  late String? _courseType;
  late final Set<int> _credits;
  late bool? _hasVacancy;
  late Set<String> _classTimes;
  int _visibleClassTimeDayCount = 5;

  CourseSelectionController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _classNoController = TextEditingController(text: controller.classNo);
    _serialNoController = TextEditingController(text: controller.serialNo);
    _departmentNameController = TextEditingController(
      text: controller.departmentName,
    );
    _collegeNameController = TextEditingController(
      text: controller.collegeName,
    );
    _instructorController = TextEditingController(text: controller.instructor);
    _courseType = controller.courseType;
    _credits = controller.credits.toSet();
    _hasVacancy = controller.hasVacancy;
    _classTimes = controller.classTimes.toSet();
  }

  @override
  void dispose() {
    _classNoController.dispose();
    _serialNoController.dispose();
    _departmentNameController.dispose();
    _collegeNameController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final contentPadding = widget.useDialogLayout
        ? const EdgeInsets.fromLTRB(28.0, 24.0, 28.0, 28.0)
        : EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0 + bottomInset);
    final content = widget.useDialogLayout
        ? _buildDialogContent(context, contentPadding)
        : _buildSheetContent(context, contentPadding);

    if (widget.useDialogLayout) {
      return SafeArea(child: content);
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _CourseSelectionPageContentState._maxSheetWidth,
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildDialogContent(
    BuildContext context,
    EdgeInsetsGeometry contentPadding,
  ) {
    return Padding(
      padding: contentPadding,
      child: Column(
        children: [
          _AdvancedFilterHeader(onClose: () => Navigator.of(context).pop()),
          const SizedBox(height: 16.0),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SingleChildScrollView(child: _buildFilters())),
                const VerticalDivider(width: 32.0),
                Expanded(child: _buildInlineClassTimePicker(context)),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          _AdvancedFilterActions(
            isLoading: controller.isLoading,
            onApply: _applyFilters,
            onClear: _clearFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildSheetContent(
    BuildContext context,
    EdgeInsetsGeometry contentPadding,
  ) {
    return SingleChildScrollView(
      padding: contentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdvancedFilterHeader(onClose: () => Navigator.of(context).pop()),
          const SizedBox(height: 12.0),
          _buildFilters(),
          const SizedBox(height: 8.0),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.isLoading ? null : _showClassTimePicker,
              icon: const Icon(Icons.schedule_outlined),
              label: Text(_classTimeButtonText),
            ),
          ),
          const SizedBox(height: 12.0),
          _AdvancedFilterActions(
            isLoading: controller.isLoading,
            onApply: _applyFilters,
            onClear: _clearFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdvancedSearchFields(
          enabled: !controller.isLoading,
          classNoController: _classNoController,
          serialNoController: _serialNoController,
          departmentNameController: _departmentNameController,
          collegeNameController: _collegeNameController,
          instructorController: _instructorController,
          onSubmitted: _applyFilters,
        ),
        const SizedBox(height: 12.0),
        Text('課程類型', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8.0),
        _DraftCourseTypeSegmentedControl(
          value: _courseType,
          enabled: !controller.isLoading,
          onChanged: (value) => setState(() => _courseType = value),
        ),
        const SizedBox(height: 12.0),
        Text('學分', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8.0),
        _DraftCreditFilterGrid(
          selectedCredits: _credits,
          enabled: !controller.isLoading,
          onToggle: _toggleCredit,
        ),
        const SizedBox(height: 12.0),
        Text('名額', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8.0),
        _DraftVacancySegmentedControl(
          value: _hasVacancy,
          enabled: !controller.isLoading,
          onChanged: (value) => setState(() => _hasVacancy = value),
        ),
      ],
    );
  }

  Widget _buildInlineClassTimePicker(BuildContext context) {
    final visibleDays = _classTimeWeekDays
        .take(_visibleClassTimeDayCount)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '上課時段',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            TextButton(
              onPressed: _classTimes.isEmpty
                  ? null
                  : () => setState(() => _classTimes.clear()),
              child: const Text('清除'),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 5, label: Text('平日')),
            ButtonSegment(value: 7, label: Text('全週')),
          ],
          selected: {_visibleClassTimeDayCount},
          onSelectionChanged: (values) {
            setState(() => _visibleClassTimeDayCount = values.single);
          },
        ),
        const SizedBox(height: 12.0),
        Expanded(
          child: _ClassTimeGrid(
            days: visibleDays,
            periods: _classTimePeriods,
            selectedValues: _classTimes,
            enabled: !controller.isLoading,
            onToggle: _toggleClassTime,
          ),
        ),
      ],
    );
  }

  String get _classTimeButtonText {
    final count = _classTimes.length;
    if (count == 0) return '選擇上課時段';
    return '已選 $count 個時段';
  }

  void _toggleCredit(int credit) {
    setState(() {
      if (!_credits.add(credit)) {
        _credits.remove(credit);
      }
    });
  }

  void _toggleClassTime(String value) {
    setState(() {
      if (!_classTimes.add(value)) {
        _classTimes.remove(value);
      }
    });
  }

  Future<void> _showClassTimePicker() async {
    final nextValues = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return _DraftClassTimePickerSheet(classTimes: _classTimes);
      },
    );
    if (nextValues == null) return;
    setState(() => _classTimes = nextValues);
  }

  void _clearFilters() {
    _classNoController.clear();
    _serialNoController.clear();
    _departmentNameController.clear();
    _collegeNameController.clear();
    _instructorController.clear();
    setState(() {
      _courseType = null;
      _credits.clear();
      _hasVacancy = null;
      _classTimes = {};
    });
  }

  void _applyFilters() {
    unawaited(
      controller
          .applyFilters(
            classNo: _classNoController.text,
            serialNo: _serialNoController.text,
            departmentName: _departmentNameController.text,
            collegeName: _collegeNameController.text,
            instructor: _instructorController.text,
            courseType: _courseType,
            credits: _credits,
            hasVacancy: _hasVacancy,
            classTimes: _classTimes,
          )
          .then((_) {
            if (mounted) Navigator.of(context).pop();
          }),
    );
  }
}

class _ActiveFilterSummary extends StatelessWidget {
  const _ActiveFilterSummary({required this.controller, required this.onClear});

  final CourseSelectionController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final chips = _filterLabels()
        .map(
          (label) =>
              Chip(label: Text(label), visualDensity: VisualDensity.compact),
        )
        .toList(growable: false);

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...chips,
        ActionChip(
          avatar: const Icon(Icons.close, size: 18.0),
          label: const Text('清除全部'),
          onPressed: controller.isLoading ? null : onClear,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  List<String> _filterLabels() {
    final labels = <String>[];
    if (controller.keyword.isNotEmpty) {
      labels.add('關鍵字：${controller.keyword}');
    }
    if (controller.classNo.isNotEmpty) {
      labels.add('課號：${controller.classNo}');
    }
    if (controller.serialNo.isNotEmpty) {
      labels.add('流水號：${controller.serialNo}');
    }
    if (controller.departmentName.isNotEmpty) {
      labels.add('系所：${controller.departmentName}');
    }
    if (controller.collegeName.isNotEmpty) {
      labels.add('學院：${controller.collegeName}');
    }
    if (controller.instructor.isNotEmpty) {
      labels.add('授課教師：${controller.instructor}');
    }
    if (controller.courseType != null) {
      labels.add('類型：${_courseTypeText(controller.courseType)}');
    }
    if (controller.credits.isNotEmpty) {
      labels.add('學分：${controller.credits.join('、')}');
    }
    if (controller.hasVacancy != null) {
      labels.add(controller.hasVacancy == true ? '尚有名額' : '已額滿');
    }
    if (controller.classTimes.isNotEmpty) {
      labels.add('時段：${controller.classTimes.length} 個');
    }
    return labels;
  }

  String _courseTypeText(String? courseType) {
    return switch (courseType) {
      'REQUIRED' => '必修',
      'ELECTIVE' => '選修',
      final value? => value,
      _ => '全部',
    };
  }
}

class _AdvancedFilterHeader extends StatelessWidget {
  const _AdvancedFilterHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('進階查詢', style: Theme.of(context).textTheme.titleLarge),
        ),
        IconButton(
          tooltip: '關閉',
          onPressed: onClose,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class _AdvancedFilterActions extends StatelessWidget {
  const _AdvancedFilterActions({
    required this.isLoading,
    required this.onApply,
    required this.onClear,
  });

  final bool isLoading;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isLoading ? null : onApply,
            icon: const Icon(Icons.tune),
            label: const Text('套用查詢'),
          ),
        ),
        const SizedBox(width: 8.0),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onClear,
          icon: const Icon(Icons.close),
          label: const Text('清除'),
        ),
      ],
    );
  }
}

class _AdvancedSearchFields extends StatelessWidget {
  const _AdvancedSearchFields({
    required this.enabled,
    required this.classNoController,
    required this.serialNoController,
    required this.departmentNameController,
    required this.collegeNameController,
    required this.instructorController,
    required this.onSubmitted,
  });

  final bool enabled;
  final TextEditingController classNoController;
  final TextEditingController serialNoController;
  final TextEditingController departmentNameController;
  final TextEditingController collegeNameController;
  final TextEditingController instructorController;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560.0;
        final fields = [
          _SearchTextField(
            controller: classNoController,
            enabled: enabled,
            label: '課號',
            hintText: '',
            icon: Icons.tag_outlined,
            onSubmitted: onSubmitted,
          ),
          _SearchTextField(
            controller: serialNoController,
            enabled: enabled,
            label: '流水號',
            hintText: '',
            icon: Icons.confirmation_number_outlined,
            onSubmitted: onSubmitted,
          ),
          _SearchTextField(
            controller: departmentNameController,
            enabled: enabled,
            label: '系所',
            hintText: '',
            icon: Icons.apartment_outlined,
            onSubmitted: onSubmitted,
          ),
          _SearchTextField(
            controller: collegeNameController,
            enabled: enabled,
            label: '學院',
            hintText: '',
            icon: Icons.account_balance_outlined,
            onSubmitted: onSubmitted,
          ),
          _SearchTextField(
            controller: instructorController,
            enabled: enabled,
            label: '授課教師',
            hintText: '',
            icon: Icons.person_search_outlined,
            onSubmitted: onSubmitted,
          ),
        ];

        if (!isWide) {
          return Column(
            children: [
              for (var index = 0; index < fields.length; index++) ...[
                fields[index],
                if (index < fields.length - 1) const SizedBox(height: 8.0),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var index = 0; index < fields.length; index += 2) ...[
              Row(
                children: [
                  Expanded(child: fields[index]),
                  const SizedBox(width: 8.0),
                  if (index + 1 < fields.length)
                    Expanded(child: fields[index + 1])
                  else
                    const Spacer(),
                ],
              ),
              if (index < fields.length - 2) const SizedBox(height: 8.0),
            ],
          ],
        );
      },
    );
  }
}

class _SearchTextField extends StatelessWidget {
  const _SearchTextField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hintText;
  final IconData icon;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (_) => onSubmitted(),
    );
  }
}

class _DraftCreditFilterGrid extends StatelessWidget {
  const _DraftCreditFilterGrid({
    required this.selectedCredits,
    required this.enabled,
    required this.onToggle,
  });

  final Set<int> selectedCredits;
  final bool enabled;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columnCount = 3;
        const spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final credit in _SearchPanel._creditOptions)
              SizedBox(
                width: itemWidth,
                child: FilterChip(
                  showCheckmark: false,
                  label: Center(child: Text('$credit 學分')),
                  selected: selectedCredits.contains(credit),
                  onSelected: enabled ? (_) => onToggle(credit) : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DraftClassTimePickerSheet extends StatefulWidget {
  const _DraftClassTimePickerSheet({required this.classTimes});

  final Set<String> classTimes;

  @override
  State<_DraftClassTimePickerSheet> createState() =>
      _DraftClassTimePickerSheetState();
}

class _DraftClassTimePickerSheetState
    extends State<_DraftClassTimePickerSheet> {
  static const _weekDays = ['一', '二', '三', '四', '五', '六', '日'];
  static const _periods = [
    '1',
    '2',
    '3',
    '4',
    'Z',
    '5',
    '6',
    '7',
    '8',
    '9',
    'A',
    'B',
    'C',
    'D',
  ];

  int _visibleDayCount = 5;
  late final Set<String> _selectedClassTimes;

  @override
  void initState() {
    super.initState();
    _selectedClassTimes = widget.classTimes.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final visibleDays = _weekDays.take(_visibleDayCount).toList();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _CourseSelectionPageContentState._maxSheetWidth,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0 + bottomInset),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '上課時段',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: _selectedClassTimes.isEmpty
                            ? null
                            : () {
                                setState(_selectedClassTimes.clear);
                              },
                        child: const Text('清除'),
                      ),
                      TextButton(
                        onPressed: () => _applySelection(context),
                        child: const Text('套用'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 5, label: Text('平日')),
                      ButtonSegment(value: 7, label: Text('全週')),
                    ],
                    selected: {_visibleDayCount},
                    onSelectionChanged: (values) {
                      setState(() => _visibleDayCount = values.single);
                    },
                  ),
                  const SizedBox(height: 12.0),
                  Expanded(
                    child: _ClassTimeGrid(
                      days: visibleDays,
                      periods: _periods,
                      selectedValues: _selectedClassTimes,
                      enabled: true,
                      onToggle: _toggleClassTime,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleClassTime(String value) {
    setState(() {
      if (!_selectedClassTimes.add(value)) {
        _selectedClassTimes.remove(value);
      }
    });
  }

  void _applySelection(BuildContext context) {
    Navigator.of(context).pop(_selectedClassTimes);
  }
}

class _ClassTimeGrid extends StatelessWidget {
  const _ClassTimeGrid({
    required this.days,
    required this.periods,
    required this.selectedValues,
    required this.enabled,
    required this.onToggle,
  });

  final List<String> days;
  final List<String> periods;
  final Set<String> selectedValues;
  final bool enabled;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        const rowHeaderWidth = 34.0;
        const cellGap = 4.0;
        final totalGapWidth = cellGap * (days.length - 1);
        final availableWidth =
            constraints.maxWidth - rowHeaderWidth - totalGapWidth;
        final cellWidth = (availableWidth / days.length).clamp(0.0, 54.0);
        const cellHeight = 30.0;

        return SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: rowHeaderWidth),
                    for (
                      var dayIndex = 0;
                      dayIndex < days.length;
                      dayIndex++
                    ) ...[
                      SizedBox(
                        width: cellWidth,
                        height: 24.0,
                        child: Center(
                          child: Text(
                            days[dayIndex],
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ),
                      if (dayIndex < days.length - 1)
                        const SizedBox(width: cellGap),
                    ],
                  ],
                ),
                const SizedBox(height: 4.0),
                for (
                  var periodIndex = 0;
                  periodIndex < periods.length;
                  periodIndex++
                ) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: rowHeaderWidth,
                        height: cellHeight,
                        child: Center(
                          child: Text(
                            periods[periodIndex],
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ),
                      for (
                        var dayIndex = 0;
                        dayIndex < days.length;
                        dayIndex++
                      ) ...[
                        _ClassTimeGridCell(
                          dayLabel: days[dayIndex],
                          period: periods[periodIndex],
                          value: '${dayIndex + 1}-${periods[periodIndex]}',
                          width: cellWidth,
                          height: cellHeight,
                          selected: selectedValues.contains(
                            '${dayIndex + 1}-${periods[periodIndex]}',
                          ),
                          enabled: enabled,
                          onToggle: onToggle,
                          colorScheme: colorScheme,
                        ),
                        if (dayIndex < days.length - 1)
                          const SizedBox(width: cellGap),
                      ],
                    ],
                  ),
                  if (periodIndex < periods.length - 1)
                    const SizedBox(height: cellGap),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ClassTimeGridCell extends StatelessWidget {
  const _ClassTimeGridCell({
    required this.dayLabel,
    required this.period,
    required this.value,
    required this.width,
    required this.height,
    required this.selected,
    required this.enabled,
    required this.onToggle,
    required this.colorScheme,
  });

  final String dayLabel;
  final String period;
  final String value;
  final double width;
  final double height;
  final bool selected;
  final bool enabled;
  final ValueChanged<String> onToggle;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$dayLabel $period',
      child: SizedBox(
        width: width,
        height: height,
        child: InkWell(
          onTap: enabled ? () => onToggle(value) : null,
          borderRadius: BorderRadius.circular(8.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primaryContainer
                  : colorScheme.surface,
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
    );
  }
}

class _DraftCourseTypeSegmentedControl extends StatelessWidget {
  const _DraftCourseTypeSegmentedControl({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = constraints.maxWidth / 3;
        return SegmentedButton<_CourseTypeFilter>(
          showSelectedIcon: false,
          style: ButtonStyle(
            fixedSize: WidgetStatePropertyAll(Size(segmentWidth, 44.0)),
          ),
          segments: const [
            ButtonSegment(value: _CourseTypeFilter.all, label: Text('全部')),
            ButtonSegment(value: _CourseTypeFilter.required, label: Text('必修')),
            ButtonSegment(value: _CourseTypeFilter.elective, label: Text('選修')),
          ],
          selected: {_selectedFilter},
          onSelectionChanged: enabled
              ? (values) => onChanged(_toCourseType(values.single))
              : null,
        );
      },
    );
  }

  _CourseTypeFilter get _selectedFilter {
    return switch (value) {
      'REQUIRED' => _CourseTypeFilter.required,
      'ELECTIVE' => _CourseTypeFilter.elective,
      _ => _CourseTypeFilter.all,
    };
  }

  String? _toCourseType(_CourseTypeFilter filter) {
    return switch (filter) {
      _CourseTypeFilter.all => null,
      _CourseTypeFilter.required => 'REQUIRED',
      _CourseTypeFilter.elective => 'ELECTIVE',
    };
  }
}

class _DraftVacancySegmentedControl extends StatelessWidget {
  const _DraftVacancySegmentedControl({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool? value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = constraints.maxWidth / 3;
        return SegmentedButton<_VacancyFilter>(
          showSelectedIcon: false,
          style: ButtonStyle(
            fixedSize: WidgetStatePropertyAll(Size(segmentWidth, 44.0)),
          ),
          segments: const [
            ButtonSegment(value: _VacancyFilter.all, label: Text('全部')),
            ButtonSegment(value: _VacancyFilter.available, label: Text('尚有名額')),
            ButtonSegment(value: _VacancyFilter.full, label: Text('已額滿')),
          ],
          selected: {_selectedFilter},
          onSelectionChanged: enabled
              ? (values) => onChanged(_toHasVacancy(values.single))
              : null,
        );
      },
    );
  }

  _VacancyFilter get _selectedFilter {
    return switch (value) {
      true => _VacancyFilter.available,
      false => _VacancyFilter.full,
      null => _VacancyFilter.all,
    };
  }

  bool? _toHasVacancy(_VacancyFilter filter) {
    return switch (filter) {
      _VacancyFilter.all => null,
      _VacancyFilter.available => true,
      _VacancyFilter.full => false,
    };
  }
}

class _LocalCourseFilterSheet extends StatefulWidget {
  const _LocalCourseFilterSheet({
    required this.onlyShowTimetableCompatibleCourses,
    required this.onlyShowSelectedCourses,
    required this.useDialogLayout,
  });

  final bool onlyShowTimetableCompatibleCourses;
  final bool onlyShowSelectedCourses;
  final bool useDialogLayout;

  @override
  State<_LocalCourseFilterSheet> createState() =>
      _LocalCourseFilterSheetState();
}

class _LocalCourseFilterSheetState extends State<_LocalCourseFilterSheet> {
  late bool _onlyShowTimetableCompatibleCourses;
  late bool _onlyShowSelectedCourses;

  @override
  void initState() {
    super.initState();
    _onlyShowTimetableCompatibleCourses =
        widget.onlyShowTimetableCompatibleCourses;
    _onlyShowSelectedCourses = widget.onlyShowSelectedCourses;
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: widget.useDialogLayout
          ? const EdgeInsets.all(24.0)
          : const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('檢視選項', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8.0),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.event_available_outlined),
            title: const Text('只顯示本頁可加入課表的課程'),
            value: _onlyShowTimetableCompatibleCourses,
            onChanged: (value) {
              setState(() => _onlyShowTimetableCompatibleCourses = value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.checklist_outlined),
            title: const Text('只顯示已加入課表的課程'),
            value: _onlyShowSelectedCourses,
            onChanged: (value) {
              setState(() => _onlyShowSelectedCourses = value);
            },
          ),
          const SizedBox(height: 8.0),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _LocalCourseFilterState(
                  onlyShowTimetableCompatibleCourses:
                      _onlyShowTimetableCompatibleCourses,
                  onlyShowSelectedCourses: _onlyShowSelectedCourses,
                ),
              ),
              child: const Text('完成'),
            ),
          ),
        ],
      ),
    );

    if (widget.useDialogLayout) {
      return content;
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _CourseSelectionPageContentState._maxSheetWidth,
          ),
          child: content,
        ),
      ),
    );
  }
}

class _LocalCourseFilterState {
  const _LocalCourseFilterState({
    required this.onlyShowTimetableCompatibleCourses,
    required this.onlyShowSelectedCourses,
  });

  final bool onlyShowTimetableCompatibleCourses;
  final bool onlyShowSelectedCourses;
}
