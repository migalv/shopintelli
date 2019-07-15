import 'package:flutter/material.dart';
import 'package:tfg/model/AppConfig.dart';

class InviteFriendsPage extends StatefulWidget {
  @override
  _InviteFriendsPageState createState() => _InviteFriendsPageState();
}

class _InviteFriendsPageState extends State<InviteFriendsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(48.0),
        child: AppBar(
          title: Text(
            'Juntos de compras!',
            textAlign: TextAlign.center,
          ),
          elevation: 0.5,
        ),
      ),
      body: Column(
        children: <Widget>[
          _buildBanner(),
          _buildInvitePeople(),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Column(
      children: <Widget>[
        Image.asset(AppConfig.shoppingWithFriendsAsset),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Invita a tus amigos, familiares, compañeros de trabajo y comparte la lista con ellos para que todos podáis añadir productos.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15.0),
          ),
        ),
      ],
    );
  }

  Widget _buildInvitePeople() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 120.0,
                width: 120.0,
                child: Image.asset(AppConfig.inviteFriendsAsset),
              ),
            ),
            borderRadius: BorderRadius.circular(80.0),
            onTap: () {},
          ),
        ),
      ],
    );
  }

}
