import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/parent_encouragement_composer_cubit.dart';
import 'encouragement_composer_content.dart';

class ParentEncouragementComposer extends StatelessWidget {
  const ParentEncouragementComposer({super.key, required this.childUserId});
  final String childUserId;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child:
          BlocBuilder<
            ParentEncouragementComposerCubit,
            ParentEncouragementComposerState
          >(
            builder: (context, state) {
              final cubit = context.read<ParentEncouragementComposerCubit>();
              return EncouragementComposerContent(
                state: state,
                onMessageSelected: cubit.selectMessage,
                onStickerSelected: cubit.selectSticker,
                onSend: () => cubit.send(childUserId),
              );
            },
          ),
    ),
  );
}
