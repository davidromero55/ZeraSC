package Zera::SC::View;

use JSON;
use base 'Zera::Base::View';

# Module Functions
sub display_home {
    my $self = shift;
  
    my $vars = {

    };
    return $self->render_template($vars);
}

sub display_product {
    my $self = shift;
    $self->param('code',$self->param('SubView')) if(!(defined $self->param('code')));
    my $id = $self->selectrow_hashref("SELECT product_id FROM sc_products WHERE code = ?", {Slice=>{}}, $self->param('code'));
    my $product = $self->selectall_arrayref("SELECT p.product_id, p.code, p.name, p.details, p.description, p.image, c.category_id, c.url_key, c.name as category, b.brand_id, b.name as brand, b.image as brand_image FROM sc_products p inner join sc_products_to_categories pc on pc.product_id = p.product_id inner join sc_categories c on pc.category_id = c.category_id inner join sc_brands b on p.brand_id = b.brand_id where p.code = ?",{Slice=>{}}, $self->param('code'));
    my $galery = $self->selectall_arrayref("select image from sc_products_images where product_id = (select product_id from  sc_products where code = ?)",{Slice=>{}}, $self->param('code'));
    my $principal = $self->selectall_arrayref("select image from sc_products  where code = ?",{Slice=>{}}, $self->param('code'));
    my $related = $self->selectall_arrayref("select p.product_id, p.code, lower(p.name) as name, p.image from sc_products p where p.product_id in (select rp.product_related_id from sc_related_product rp where rp.product_id = ?)",{Slice=>{}}, $id->{product_id});
    my $vars = {
        products => $product,
        imagenes => $galery,
        principal => $principal,
        relacionados => $related,
    };
    return $self->render_template($vars);
}

sub display_result {
    my $self = shift;

    my $entry = $self->selectall_arrayref("SELECT p.product_id, p.code, p.name, p.description, p.image FROM sc_products p  WHERE p.name LIKE ? ", {Slice=>{}}, '%'.$self->param('zl_q').'%');

    my $vars = {
        entradas => $entry,
    };
    return $self->render_template($vars);
}

sub display_category {
    my $self = shift;
    $self->param('url',$self->param('SubView')) if(!(defined $self->param('url')));
    my $id = $self->selectrow_hashref("SELECT category_id FROM sc_categories WHERE url_key = ?", {Slice=>{}}, $self->param('url'));
    my $childs = $self->selectall_arrayref("SELECT category_id, url_key, lower(name) as name, image from sc_categories where parent_id = ? ", {Slice=>{}}, $id->{category_id});
    my $entry = $self->selectall_arrayref("SELECT p.product_id, p.code, p.name, p.description, p.image, b.name as marca FROM sc_products_to_categories pc INNER JOIN sc_products p on p.product_id = pc.product_id INNER JOIN sc_brands b on b.brand_id = p.brand_id WHERE pc.category_id = ? ", {Slice=>{}}, $id->{category_id});

    my $vars = {
        entradas => $entry,
        hijos => $childs,
        id => $id->{category_id},
        url_key =>$self->param('url'),
    };
    return $self->render_template($vars);
}

sub display_groups {
    my $self = shift;

    $self->set_title('Banner Groups');
    $self->add_search_box();
    $self->set_add_btn('/SC/GroupEdit/New');
    $self->add_btn('/SC','Back to banners');

    my $where;
    my @params;
    if($self->param('zl_q')){
        $where .= " name LIKE ? ";
        push(@params,'%' . $self->param('zl_q') .'%');
    }
    my $list = Zera::List->new($self->{Zera},{
        sql => {
            select => "group_id, name, group_type ",
            from =>"banners_groups e",
            order_by => "",
            where => $where,
            params => \@params,
            limit => "30",
        },
        link => {
            key => "group_id",
            hidde_key_col => 1,
            location => '/SC/GroupEdit',
            transit_params => {},
        },
        debug => 1,
    });

    $list->get_data();
    $list->on_off('active');
    $list->columns_align(['left','left','center']);

    my $vars = {
        list => $list->print(),
    };

    return $self->render_template($vars);
}

sub display_quienes{
    my $self = shift;
    return  $self->render_template();
}

sub display_group_edit {
    my $self = shift;
    my $values = {};
    my @submit = ("Save");

    $self->param('group_id',$self->param('SubView')) if(!(defined $self->param('group_id')));

    # Title
    ($self->param('SubView') eq 'New') ? $self->set_title('Add Banner Group') : $self->set_title('Edit Banner Group');

    # Helper buttons
    $self->add_btn('/SC/Groups','Back');

    # JS
    $self->add_jsfile('admin-blog');

    # Values
    if($self->param('group_id') ne 'New'){
        $values = $self->selectrow_hashref("SELECT * FROM banners_groups WHERE group_id=?",{},$self->param('group_id'));
        #$values->{display_options} = decode_json($values->{display_options});
        push(@submit, 'Delete');
    }else{
        $values = {
            date => $self->selectrow_array('SELECT DATE(NOW())'),
            active => 1,
        };
    }

    # Form
    my $form = $self->form({
        method   => 'POST',
        fields   => [qw/name group_type /],
        submits  => \@submit,
        values   => $values,
    });

    #$form->field('group_id',{span=>'col-md-3', required=>1});
    $form->field('name',{span=>'col-md-8', required=>1});
    $form->field('group_type',{span=>'col-md-4', required=>1});

    $form->submit('Delete',{class=>'btn btn-danger'});

    return $form->render();
}

1;
