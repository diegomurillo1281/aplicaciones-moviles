1  import 'package:flutter/material.dart';
 2  import '../theme/app_theme.dart';
 3  
 4  class PrimaryButton extends StatelessWidget {
 5    final String text;
 6    final VoidCallback? onPressed;
 7    final bool isLoading;
 8    final bool isDisabled;
 9    final IconData? icon;
10  
11    const PrimaryButton({
12      Key? key,
13      required this.text,
14      this.onPressed,
15      this.isLoading = false,
16      this.isDisabled = false,
17      this.icon,
18    }) : super(key: key);
19  
20    @override
21    Widget build(BuildContext context) {
22      final theme = Theme.of(context);
23      final isClickable = !isDisabled && !isLoading && onPressed != null;
24  
25      return Semantics(
26        button: true,
27        enabled: isClickable,
28        label: text,
29        child: ConstrainedBox(
30          constraints: const BoxConstraints(minHeight: 48.0),
31          child: ElevatedButton(
32            style: ElevatedButton.styleFrom(
33              backgroundColor: theme.colorScheme.primary,
34              foregroundColor: theme.colorScheme.onPrimary,
35              disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.4),
36              shape: RoundedRectangleBorder(
37                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
38              ),
39              padding: const EdgeInsets.symmetric(
40                horizontal: AppTokens.spaceMd,
41                vertical: AppTokens.spaceSm,
42              ),
43            ),
44            onPressed: isClickable ? onPressed : null,
45            child: isLoading
46                ? SizedBox(
47                    height: 20,
48                    width: 20,
49                    child: CircularProgressIndicator(
50                      strokeWidth: 2.0,
51                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
52                    ),
53                  )
54                : Row(
55                    mainAxisSize: MainAxisSize.min,
56                    mainAxisAlignment: MainAxisAlignment.center,
57                    children: [
58                      if (icon != null) ...[
59                        Icon(icon, size: 20),
60                        const SizedBox(width: AppTokens.spaceSm),
61                      ],
62                      Text(
63                        text,
64                        style: theme.textTheme.bodyMedium?.copyWith(
65                          color: theme.colorScheme.onPrimary,
66                          fontWeight: FontWeight.bold,
67                        ),
68                      ),
69                    ],
70                  ),
71          ),
72        ),
73      );
74    }
75  }