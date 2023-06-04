import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../config/route_coordinates.dart';
import '../style/constants.dart';

class TeamPageMobile extends StatefulWidget {
  const TeamPageMobile({
    super.key,
  });

  @override
  State<TeamPageMobile> createState() => _TeamPageMobileState();
}

class _TeamPageMobileState extends State<TeamPageMobile> {
  int face_choice = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
            margin: const EdgeInsets.all(Constants.defaultPadding),
            width: 500,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(Constants.defaultPadding)),
            ),
            child: Stack(
              children: [
                Image.asset("assets/team.jpg", fit: BoxFit.cover),
              ],
            )),

        if(face_choice == -1)
          Container(
            padding: const EdgeInsets.all(Constants.defaultPadding),
            child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Meet the Team", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                  SizedBox(height: Constants.defaultPadding),
                  Text("This project was created by five computer science junior students at the University of the Philippines Diliman in partial fullfillment of their Capstone Project for the Systems Series (CS 20, 21, 140, 145).\n\nThis project demonstrates applications in circuit design, computer architecture, multithreaded processes, and network communication to create a prototype that boasts the capability and practical use of IoT Devices to address the 11th United Nations Sustainable Development Goal: Sustainable Cities and Communities.", style: TextStyle(fontStyle: FontStyle.italic), textAlign: TextAlign.start),
                ]
            ),
          ),

        if(face_choice != -1)
          Container(
            padding: const EdgeInsets.only(right: Constants.defaultPadding),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Center(child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                          Members[face_choice].img,
                          fit: BoxFit.cover
                      ),
                    ),
                  )),
                  const SizedBox(height: Constants.defaultPadding*2),
                  Text("Name: ${Members[face_choice].fullname}"),
                  const SizedBox(height: Constants.defaultPadding),
                  Text(Members[face_choice].description, style: const TextStyle(fontStyle: FontStyle.italic), textAlign: TextAlign.justify),
                  const SizedBox(height: Constants.defaultPadding),
                  Text("Github: ${Members[face_choice].github}\nEmail: ${Members[face_choice].email}\nLinkedIn: ${Members[face_choice].linkedin}")
                ]
            ),
          )
      ],
    );
  }
}