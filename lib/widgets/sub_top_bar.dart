import 'package:flutter/material.dart';

class SubTopBar extends StatefulWidget {
  final VoidCallback? onMemoPressed;
  final VoidCallback? onToggleSiderbar;
  final String subtitle;
  const SubTopBar({
    super.key,
    this.onMemoPressed,
    this.onToggleSiderbar,
    this.subtitle = "",
  });

  @override
  State<SubTopBar> createState() => _SubTopBarState();
}

class _SubTopBarState extends State<SubTopBar> {
  // 텍스트 입력을 위한 컨트롤러
  final TextEditingController _titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // double horizontalPadding = MediaQuery.of(context).size.width * 0.9;
    double horizontalPadding =700;
    double verticalPadding = MediaQuery.of(context).size.height * 0.12;
    double responsiveFontSize = verticalPadding*0.25;

    return Container(
      alignment: Alignment.center, // 💡 핵심 속성
      width: horizontalPadding,
      height: verticalPadding/2,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding.clamp(10, 10), vertical: 10, ),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(50),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.white.withAlpha(50),width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center, // 컨테이너 내부 요소 중앙 정렬
              height: verticalPadding*0.5,
              padding: const EdgeInsets.symmetric(horizontal: 5,vertical: 5),
              // Icon(Icons.star, color: Colors.yellow, size: 30.0),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(40),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.white.withAlpha(50),width: 1),
              ),
              // double responsiveFontSize = (verticalPadding / 400) * 16,
              child: TextField(
                // textAlignVertical: TextAlignVertical.center,
                textAlign: TextAlign.center,
                controller: _titleController,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: responsiveFontSize,
                  height: verticalPadding*0.02,
                  // fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  hintText: "*다음끝장: 단1개 목표 입력...",
                  hintStyle: TextStyle(color: Colors.greenAccent, fontSize: responsiveFontSize/2,height: 1.0),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 1.0, horizontal: 10.0),
                  // contentPadding: EdgeInsets.symmetric.,
                ),
              ),

            ),
          ),


          IconButton(
              icon: Icon(Icons.app_registration_rounded, color: Colors.white),
              iconSize: responsiveFontSize*1.3,
              onPressed: widget.onMemoPressed,
              tooltip: "다음할일"
          ),

        ],
      ),

    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}