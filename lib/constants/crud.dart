// ignore_for_file: inference_failure_on_collection_literal

final Map<String, dynamic> kCrudEmpty = {
  'categories': {
    'operations': {
      'create': [{}],
      'update': [{}],
      'delete': [{}],
    },
  },
  'tasks': {
    'operations': {
      'create': [{}],
      'update': [{}],
      'delete': [{}],
    },
  },
};

final Map<String, dynamic> kCrudExample = {
  'categories': {
    'operations': {
      'create': [
        {
          'title': 'Неделя 1: Сортировка',
          'short_title': 'Сортировка',
          'description': 'example description',
          'sorting_number': 1,
        }
      ],
      'update': [
        {
          'id': 0,
          'title': 'example title',
          'short_title': 'example short_title',
          'description': 'example description',
          'sorting_number': 1,
        }
      ],
      'delete': [
        {
          'id': 0,
        }
      ],
    },
  },
  'tasks': {
    'operations': {
      'create': [
        {
          'slug': 'decode-ways',
          'category': 0,
          'title': '91. Decode Ways',
          'link': 'https://leetcode.com/problems/decode-ways/description/',
          'complexity': 'easy|medium|hard',
        }
      ],
      'update': [
        {
          'slug': 'decode-ways',
          'category': 0,
          'title': '91. Decode Ways',
          'link': 'https://leetcode.com/problems/decode-ways/description/',
          'complexity': 'hard',
        }
      ],
      'delete': [
        {
          'slug': 'decode-ways',
        }
      ],
    },
  },
};
