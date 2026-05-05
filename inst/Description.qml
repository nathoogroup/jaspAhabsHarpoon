import QtQuick
import JASP.Module

Description
{
	name		: "jaspAhabsHarpoon"
	title		: qsTr("Ahab's Harpoon")
	description	: qsTr("Detecting Type I errors via Bayes/NHST conflict")
	version		: "0.1"
	author		: "Evan Strasdin, Puneet Velidi, Zhengxiao Wei, Farouk S. Nathoo"
	maintainer	: "Evan Strasdin <evn.strsdn@pm.me>"
	website		: "https://github.com/nathoogroup/jaspAhabsHarpoon"
	license		: "GPL (>= 2)"
	icon        : "harpoon.png"
	preloadData: true
	requiresData: true

	GroupTitle
	{
		title:	qsTr("Detecting type I errors")
	}

	Analysis
	{
	  title: qsTr("eJAB Analysis")
	  menu: qsTr("eJAB Analysis")
	  func: "ejabAnalysis"
	  qml: "EjabAnalysis.qml"
	}
}
