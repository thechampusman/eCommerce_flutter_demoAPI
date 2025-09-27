import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_event.dart';
import '../bloc/theme/theme_state.dart';
import '../models/api_user.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import '../widgets/glassmorphic_container.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 400;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? Color(0xFFFBF9F6) : null,
      
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context, isTablet, isMobile),
            Expanded(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthAuthenticated) {
                    return _buildAuthenticatedProfile(
                      context,
                      state.user,
                      isTablet,
                      isMobile,
                    );
                  } else {
                    return _buildUnauthenticatedProfile(
                      context,
                      isTablet,
                      isMobile,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(
    BuildContext context,
    bool isTablet,
    bool isMobile,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GlassmorphicContainer(
        blur: 14,
        opacity: 0.12,
        borderRadius: BorderRadius.circular(14),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.arrow_back_ios,
                size: isTablet ? 22 : 20,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment(-0.18, 0), 
                child: Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStat(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool showIcon = true,
    Color? labelColor,
    Color? valueColor,
  }) {
    return Row(
      children: [
        if (showIcon)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          )
        else
          SizedBox(width: 0, height: 36),
        SizedBox(width: showIcon ? 6 : 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color:
                    labelColor ?? Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    valueColor ??
                    Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title) {
    return GlassmorphicContainer(
      blur: 12,
      opacity: 0.09,
      borderRadius: BorderRadius.circular(14),
      padding: EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedProfile(
    BuildContext context,
    ApiUser user,
    bool isTablet,
    bool isMobile,
  ) {
    
    final headerHeight = isTablet
        ? 180.0
        : 180.0; 
    final isLight = Theme.of(context).brightness == Brightness.light;
    return SingleChildScrollView(
      child: Column(
        children: [
          
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: headerHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.95),
                      Theme.of(context).colorScheme.primary.withOpacity(0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                
                top: headerHeight - (isTablet ? 20 : 170),
                child: GlassmorphicContainer(
                  blur: 20,
                  opacity: 0.14,
                  borderRadius: BorderRadius.circular(20),
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      
                      Container(
                        width: isMobile ? 80 : (isTablet ? 110 : 90),
                        height: isMobile ? 80 : (isTablet ? 110 : 90),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: user.image.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: user.image,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceVariant,
                                  child: Icon(
                                    Icons.person,
                                    size: 48,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 16),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.firstName} ${user.lastName}',
                              style: TextStyle(
                                fontSize: isTablet ? 22 : 18,
                                fontWeight: FontWeight.bold,
                                color: isLight
                                    ? Colors.white
                                    : Theme.of(
                                        context,
                                      ).textTheme.headlineMedium?.color,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: isLight
                                    ? Colors.white
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                _buildSmallStat(
                                  context,
                                  Icons.receipt_long,
                                  'Orders',
                                  '12',
                                  labelColor: isLight ? Colors.white : null,
                                  valueColor: isLight ? Colors.white : null,
                                ),
                                SizedBox(width: 12),
                                _buildSmallStat(
                                  context,
                                  Icons.favorite_border,
                                  'Wishlist',
                                  '8',
                                  showIcon: false,
                                  labelColor: isLight ? Colors.white : null,
                                  valueColor: isLight ? Colors.white : null,
                                ),
                                SizedBox(width: 12),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                    ],
                  ),
                ),
              ),
            ],
          ),

          
          SizedBox(height: isMobile ? 12 : (isTablet ? 8 : 6)),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : (isTablet ? 24 : 20),
            ),
            child: Column(
              children: [
                
                GridView.count(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: isTablet ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _buildActionTile(context, Icons.list_alt, 'Orders'),
                    _buildActionTile(context, Icons.favorite, 'Wishlist'),
                    _buildActionTile(context, Icons.payment, 'Payments'),
                    _buildActionTile(context, Icons.location_on, 'Addresses'),
                  ],
                ),

                SizedBox(height: 18),

                
                GlassmorphicContainer(
                  blur: 16,
                  opacity: 0.12,
                  borderRadius: BorderRadius.circular(16),
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Divider(
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                      ),
                      SizedBox(height: 8),
                      _infoRow(context, 'Username', '${user.username}'),
                      _infoRow(context, 'User ID', user.id.toString()),
                      _infoRow(context, 'Gender', user.gender),
                    ],
                  ),
                ),

                SizedBox(height: 18),

                
                GlassmorphicContainer(
                  blur: 16,
                  opacity: 0.12,
                  borderRadius: BorderRadius.circular(16),
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: BlocBuilder<ThemeBloc, ThemeState>(
                    builder: (context, themeState) {
                      final isDarkMode =
                          themeState is ThemeLoaded && themeState.isDarkMode;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dark Mode',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isDarkMode ? 'Enabled' : 'Disabled',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: isDarkMode,
                            onChanged: (v) => context.read<ThemeBloc>().add(
                              ThemeChanged(isDarkMode: v),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                SizedBox(height: 18),

                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text('Logout'),
                        content: Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(c).pop(),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(c).pop();
                              context.read<AuthBloc>().add(
                                AuthLogoutRequested(),
                              );
                            },
                            child: Text('Logout'),
                          ),
                        ],
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedProfile(
    BuildContext context,
    bool isTablet,
    bool isMobile,
  ) {
    
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: isTablet ? 220 : 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.95),
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: GlassmorphicContainer(
                blur: 18,
                opacity: 0.14,
                borderRadius: BorderRadius.circular(18),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: isTablet ? 64 : 48,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isTablet ? 20 : 16,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Sign in to access your profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 22 : 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 24),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : (isTablet ? 24 : 20),
            ),
            child: Column(
              children: [
                
                GlassmorphicContainer(
                  blur: 14,
                  opacity: 0.12,
                  borderRadius: BorderRadius.circular(16),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Why create an account?',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildBenefitItem(
                        context,
                        Icons.shopping_cart,
                        'Track Orders',
                        'Monitor payments & delivery',
                        isTablet,
                        isMobile,
                      ),
                      _buildBenefitItem(
                        context,
                        Icons.favorite,
                        'Save Favorites',
                        'Create wishlists and save items',
                        isTablet,
                        isMobile,
                      ),
                      _buildBenefitItem(
                        context,
                        Icons.local_offer,
                        'Exclusive Deals',
                        'Member-only discounts',
                        isTablet,
                        isMobile,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Sign In', style: TextStyle(fontSize: 16)),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(width: 2),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Create Account',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    bool isTablet,
    bool isMobile,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 16 : (isTablet ? 20 : 18)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : (isTablet ? 12 : 10)),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: isTablet ? 28 : (isMobile ? 20 : 24),
            ),
          ),
          SizedBox(width: isMobile ? 12 : (isTablet ? 16 : 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : (isMobile ? 14 : 16),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : (isMobile ? 12 : 14),
                    color: Theme.of(context).hintColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
